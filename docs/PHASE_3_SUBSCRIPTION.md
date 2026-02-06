# Phase 3: サブスクリプション機能（Stripe Billing）

## 目標

Stripe Billingを使用したサブスクリプション機能を実装する。7日間の無料トライアル、自動課金、Customer Portalを含む。

## 前提条件

- Phase 2（認証機能）が完了していること
- Stripeアカウントが作成済みであること
- StripeのテストモードAPIキーを取得済みであること

## 実装手順

### 1. Subscriptionモデル作成

```bash
rails generate model Subscription \
  user:references \
  stripe_customer_id:string \
  stripe_subscription_id:string \
  stripe_price_id:string \
  status:string \
  trial_ends_at:datetime \
  current_period_start:datetime \
  current_period_end:datetime \
  canceled_at:datetime \
  ends_at:datetime
```

### 2. マイグレーションファイルの編集

```ruby
# db/migrate/xxxxxx_create_subscriptions.rb
class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      
      # Stripe関連
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :stripe_price_id
      
      # ステータス
      t.string :status, default: 'inactive', null: false
      
      # トライアル
      t.datetime :trial_ends_at
      
      # 課金期間
      t.datetime :current_period_start
      t.datetime :current_period_end
      
      # 解約
      t.datetime :canceled_at
      t.datetime :ends_at

      t.timestamps
    end
    
    add_index :subscriptions, :user_id, unique: true
    add_index :subscriptions, :stripe_customer_id
    add_index :subscriptions, :stripe_subscription_id
    add_index :subscriptions, :status
  end
end
```

```bash
rails db:migrate
```

### 3. Subscriptionモデルの実装

```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  belongs_to :user
  
  # ステータス列挙型
  enum status: {
    inactive: 'inactive',
    trial: 'trial',
    active: 'active',
    past_due: 'past_due',
    canceled: 'canceled'
  }, _prefix: true
  
  # バリデーション
  validates :user_id, uniqueness: true
  validates :status, presence: true
  
  # スコープ
  scope :active_subscriptions, -> { where(status: ['trial', 'active']) }
  
  # アクセス可能判定
  def accessible?
    status_trial? || status_active?
  end
  
  # トライアル期限切れチェック
  def trial_expired?
    status_trial? && trial_ends_at && trial_ends_at < Time.current
  end
end
```

### 4. Userモデルの更新

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  has_one :subscription, dependent: :destroy
  
  # サブスクリプション状態チェック
  def subscription_active?
    subscription&.accessible?
  end
  
  # トライアル開始可能か
  def can_start_trial?
    subscription.nil? || subscription.status_inactive?
  end
end
```

### 5. Stripe Price作成（Rake タスク）

```ruby
# lib/tasks/stripe.rake
namespace :stripe do
  desc "Create subscription product and price"
  task create_subscription_product: :environment do
    # Productを作成
    product = Stripe::Product.create({
      name: 'TOEFL セクション別演習 月額プラン',
      description: 'Reading, Listening, Speaking, Writingの練習問題にアクセス可能'
    })
    
    # Priceを作成
    price = Stripe::Price.create({
      product: product.id,
      unit_amount: 2980_00,  # ¥2,980
      currency: 'jpy',
      recurring: { interval: 'month' }
    })
    
    puts "=== Stripe Product Created ==="
    puts "Product ID: #{product.id}"
    puts "Price ID: #{price.id}"
    puts "\nAdd to .env:"
    puts "STRIPE_SUBSCRIPTION_PRICE_ID=#{price.id}"
  end
end
```

```bash
# タスク実行
rails stripe:create_subscription_product

# .envに追加
# STRIPE_SUBSCRIPTION_PRICE_ID=price_xxxxxxxxxxxxx
```

### 6. Subscriptionsコントローラー作成

```bash
rails generate controller Subscriptions new create success portal
```

```ruby
# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  
  def new
    if current_user.subscription_active?
      redirect_to dashboard_path, alert: 'すでにサブスクリプションに登録されています'
      return
    end
  end
  
  def create
    # Stripe Customer作成または取得
    customer = find_or_create_stripe_customer
    
    # Checkout Session作成
    session = Stripe::Checkout::Session.create({
      customer: customer.id,
      mode: 'subscription',
      line_items: [{
        price: ENV['STRIPE_SUBSCRIPTION_PRICE_ID'],
        quantity: 1
      }],
      subscription_data: {
        trial_period_days: 7,
        metadata: { user_id: current_user.id }
      },
      success_url: subscription_success_url,
      cancel_url: new_subscription_url
    })
    
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to new_subscription_path, alert: "エラーが発生しました: #{e.message}"
  end
  
  def success
    redirect_to dashboard_path, notice: '7日間の無料トライアルを開始しました！'
  end
  
  def portal
    unless current_user.subscription&.stripe_customer_id
      redirect_to dashboard_path, alert: 'サブスクリプションが見つかりません'
      return
    end
    
    session = Stripe::BillingPortal::Session.create({
      customer: current_user.subscription.stripe_customer_id,
      return_url: dashboard_url
    })
    
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to dashboard_path, alert: "エラーが発生しました: #{e.message}"
  end
  
  private
  
  def find_or_create_stripe_customer
    if current_user.subscription&.stripe_customer_id
      Stripe::Customer.retrieve(current_user.subscription.stripe_customer_id)
    else
      Stripe::Customer.create({
        email: current_user.email,
        metadata: { user_id: current_user.id }
      })
    end
  end
end
```

### 7. Webhookコントローラー作成

```bash
rails generate controller Webhooks::Stripe create
```

```ruby
# app/controllers/webhooks/stripe_controller.rb
class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']
    
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error "Webhook error: #{e.message}"
      return head :bad_request
    end
    
    case event.type
    when 'customer.subscription.created'
      handle_subscription_created(event.data.object)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object)
    end
    
    head :ok
  end
  
  private
  
  def handle_subscription_created(stripe_subscription)
    user = find_user_from_subscription(stripe_subscription)
    return unless user
    
    subscription = user.subscription || user.build_subscription
    
    subscription.update!(
      stripe_customer_id: stripe_subscription.customer,
      stripe_subscription_id: stripe_subscription.id,
      stripe_price_id: stripe_subscription.items.data[0].price.id,
      status: stripe_subscription.status == 'trialing' ? 'trial' : 'active',
      trial_ends_at: stripe_subscription.trial_end ? Time.at(stripe_subscription.trial_end) : nil,
      current_period_start: Time.at(stripe_subscription.current_period_start),
      current_period_end: Time.at(stripe_subscription.current_period_end)
    )
    
    Rails.logger.info "Subscription created for user #{user.id}"
  end
  
  def handle_subscription_updated(stripe_subscription)
    subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return unless subscription
    
    subscription.update!(
      status: map_stripe_status(stripe_subscription.status),
      current_period_start: Time.at(stripe_subscription.current_period_start),
      current_period_end: Time.at(stripe_subscription.current_period_end),
      canceled_at: stripe_subscription.canceled_at ? Time.at(stripe_subscription.canceled_at) : nil
    )
  end
  
  def handle_subscription_deleted(stripe_subscription)
    subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return unless subscription
    
    subscription.update!(
      status: 'canceled',
      canceled_at: Time.current,
      ends_at: Time.at(stripe_subscription.current_period_end)
    )
  end
  
  def handle_payment_succeeded(invoice)
    subscription = Subscription.find_by(stripe_customer_id: invoice.customer)
    return unless subscription
    
    # トライアルから有料への移行
    if subscription.status_trial? && invoice.billing_reason == 'subscription_cycle'
      subscription.update!(status: 'active')
    end
  end
  
  def handle_payment_failed(invoice)
    subscription = Subscription.find_by(stripe_customer_id: invoice.customer)
    return unless subscription
    
    subscription.update!(status: 'past_due')
  end
  
  def find_user_from_subscription(stripe_subscription)
    if stripe_subscription.metadata.user_id
      User.find_by(id: stripe_subscription.metadata.user_id)
    else
      customer = Stripe::Customer.retrieve(stripe_subscription.customer)
      User.find_by(email: customer.email)
    end
  end
  
  def map_stripe_status(stripe_status)
    case stripe_status
    when 'trialing' then 'trial'
    when 'active' then 'active'
    when 'past_due' then 'past_due'
    when 'canceled', 'unpaid' then 'canceled'
    else 'inactive'
    end
  end
end
```

### 8. ルーティング設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  root 'pages#home'
  
  # Subscriptions
  resources :subscriptions, only: [:new, :create] do
    collection do
      get :success
      get :portal
    end
  end
  
  # Webhooks
  namespace :webhooks do
    post 'stripe', to: 'stripe#create'
  end
  
  # Dashboard
  get 'dashboard', to: 'dashboard#index'
end
```

### 9. ダッシュボードビューの更新

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-8">ダッシュボード</h1>
  
  <!-- サブスクリプション状態 -->
  <div class="bg-white shadow rounded-lg p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">サブスクリプション状態</h2>
    
    <% if current_user.subscription_active? %>
      <div class="flex items-center justify-between">
        <div>
          <p class="text-green-600 font-medium text-lg">
            <% if current_user.subscription.status_trial? %>
              ✓ トライアル中
            <% else %>
              ✓ 有効
            <% end %>
          </p>
          
          <% if current_user.subscription.trial_ends_at %>
            <p class="text-gray-600 text-sm mt-1">
              トライアル終了日: <%= current_user.subscription.trial_ends_at.strftime('%Y年%m月%d日') %>
            </p>
          <% end %>
          
          <% if current_user.subscription.current_period_end %>
            <p class="text-gray-600 text-sm">
              次回課金日: <%= current_user.subscription.current_period_end.strftime('%Y年%m月%d日') %>
            </p>
          <% end %>
        </div>
        
        <%= link_to "サブスクリプション管理", subscription_portal_path, 
            class: "bg-gray-600 text-white px-4 py-2 rounded hover:bg-gray-700" %>
      </div>
      
      <!-- セクション別演習へのリンク -->
      <div class="mt-6 pt-6 border-t">
        <h3 class="font-semibold mb-3">セクション別演習</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <a href="#" class="bg-blue-100 p-4 rounded text-center hover:bg-blue-200">
            <div class="text-2xl mb-2">📖</div>
            <div class="font-medium">Reading</div>
          </a>
          <a href="#" class="bg-green-100 p-4 rounded text-center hover:bg-green-200">
            <div class="text-2xl mb-2">🎧</div>
            <div class="font-medium">Listening</div>
          </a>
          <a href="#" class="bg-purple-100 p-4 rounded text-center hover:bg-purple-200">
            <div class="text-2xl mb-2">🗣️</div>
            <div class="font-medium">Speaking</div>
          </a>
          <a href="#" class="bg-yellow-100 p-4 rounded text-center hover:bg-yellow-200">
            <div class="text-2xl mb-2">✍️</div>
            <div class="font-medium">Writing</div>
          </a>
        </div>
      </div>
    <% else %>
      <div class="bg-blue-50 border border-blue-200 rounded p-4">
        <p class="text-blue-800 mb-4">
          セクション別演習を利用するには、サブスクリプションへの登録が必要です。
        </p>
        <%= link_to "7日間無料トライアルを始める", new_subscription_path, 
            class: "bg-blue-600 text-white px-6 py-3 rounded hover:bg-blue-700 inline-block" %>
      </div>
    <% end %>
  </div>
</div>
```

### 10. サブスクリプション登録ページ

```erb
<!-- app/views/subscriptions/new.html.erb -->
<div class="container mx-auto px-4 py-8 max-w-2xl">
  <h1 class="text-3xl font-bold mb-8">サブスクリプション登録</h1>
  
  <div class="bg-white shadow-lg rounded-lg overflow-hidden">
    <div class="bg-blue-600 text-white p-6">
      <h2 class="text-2xl font-bold">月額プラン</h2>
      <p class="text-blue-100 mt-2">すべてのセクション別演習にアクセス</p>
    </div>
    
    <div class="p-6">
      <div class="text-center mb-6">
        <div class="text-4xl font-bold text-gray-900">¥2,980</div>
        <div class="text-gray-600">/ 月</div>
      </div>
      
      <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
        <p class="text-green-800 font-medium">✓ 7日間無料トライアル</p>
        <p class="text-green-700 text-sm mt-1">
          トライアル期間中はいつでもキャンセル可能です。課金は発生しません。
        </p>
      </div>
      
      <h3 class="font-semibold mb-3">プランに含まれるもの：</h3>
      <ul class="space-y-2 mb-6">
        <li class="flex items-start">
          <span class="text-green-600 mr-2">✓</span>
          <span>Reading セクション別演習（無制限）</span>
        </li>
        <li class="flex items-start">
          <span class="text-green-600 mr-2">✓</span>
          <span>Listening セクション別演習（無制限）</span>
        </li>
        <li class="flex items-start">
          <span class="text-green-600 mr-2">✓</span>
          <span>Speaking セクション別演習（無制限）</span>
        </li>
        <li class="flex items-start">
          <span class="text-green-600 mr-2">✓</span>
          <span>Writing セクション別演習（無制限）</span>
        </li>
      </ul>
      
      <%= button_to "無料トライアルを始める", subscriptions_path, 
          method: :post,
          class: "w-full bg-blue-600 text-white py-3 px-6 rounded-lg hover:bg-blue-700 font-medium text-lg" %>
      
      <p class="text-sm text-gray-600 text-center mt-4">
        決済はStripeを通じて安全に処理されます
      </p>
    </div>
  </div>
</div>
```

## 動作確認

### 1. Stripe CLIのセットアップ

```bash
# Stripe CLIをインストール（macOS）
brew install stripe/stripe-cli/stripe

# ログイン
stripe login

# Webhookをローカルにフォワード
stripe listen --forward-to localhost:3000/webhooks/stripe

# Webhook Secretをコピーして.envに追加
# STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
```

### 2. テストフロー

1. サーバー起動: `bin/dev`
2. ログイン
3. ダッシュボードから「7日間無料トライアルを始める」をクリック
4. Stripe Checkout画面でテストカード番号を入力:
   - カード番号: `4242 4242 4242 4242`
   - 有効期限: 任意の未来の日付
   - CVC: 任意の3桁
5. 支払い情報を入力して登録
6. ダッシュボードにリダイレクトされ、サブスクリプションが有効になっていることを確認
7. Stripe CLIでWebhookイベントを確認

### 3. Customer Portal確認

1. ダッシュボードから「サブスクリプション管理」をクリック
2. Stripe Customer Portalが開く
3. 解約、支払い方法変更などが可能なことを確認

## 確認ポイント

- [ ] Subscriptionモデルが正しく作成されている
- [ ] Stripe Priceが作成されている（.envに設定済み）
- [ ] 無料トライアル登録が完了する
- [ ] Webhookイベントが正しく処理される
- [ ] ダッシュボードにサブスクリプション状態が表示される
- [ ] Customer Portalにアクセスできる
- [ ] トライアル期間が正しく表示される

## トラブルシューティング

### Webhookが届かない

Stripe CLIが起動しているか確認：
```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

### トライアルが開始されない

1. Webhookイベントログを確認
2. `customer.subscription.created`イベントが処理されているか
3. Subscriptionレコードが作成されているか確認

## 次のフェーズ

Phase 3が完了したら、Phase 4（模擬試験購入機能）に進んでください。

```
Phase 4: Stripe Checkoutによる模擬試験の単発購入機能
- MockTestモデル作成
- Purchaseモデル作成
- 購入フロー実装
- 重複購入防止
```

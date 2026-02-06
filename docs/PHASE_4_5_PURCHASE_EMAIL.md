# Phase 4-5: 模擬試験購入 & メール通知機能

## 目標

Stripe Checkoutによる模擬試験の単発購入機能と、SendGridを使用したメール通知システムを実装する。

## Phase 4: 模擬試験購入機能

### 1. MockTestモデル作成

```bash
rails generate model MockTest \
  title:string \
  description:text \
  price_cents:integer \
  stripe_price_id:string \
  difficulty:string \
  time_limit_minutes:integer \
  published:boolean
```

```ruby
# db/migrate/xxxxxx_create_mock_tests.rb
class CreateMockTests < ActiveRecord::Migration[7.0]
  def change
    create_table :mock_tests do |t|
      t.string :title, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.string :stripe_price_id
      t.string :difficulty, default: 'medium'
      t.integer :time_limit_minutes, default: 180
      t.boolean :published, default: false

      t.timestamps
    end
    
    add_index :mock_tests, :published
  end
end
```

### 2. Purchaseモデル作成

```bash
rails generate model Purchase \
  user:references \
  mock_test:references \
  stripe_payment_intent_id:string \
  stripe_checkout_session_id:string \
  amount_cents:integer \
  currency:string \
  status:string
```

```ruby
# db/migrate/xxxxxx_create_purchases.rb
class CreatePurchases < ActiveRecord::Migration[7.0]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :mock_test, null: false, foreign_key: true
      t.string :stripe_payment_intent_id
      t.string :stripe_checkout_session_id
      t.integer :amount_cents, null: false
      t.string :currency, default: 'jpy', null: false
      t.string :status, default: 'pending', null: false

      t.timestamps
    end
    
    add_index :purchases, [:user_id, :mock_test_id], unique: true
    add_index :purchases, :stripe_payment_intent_id
    add_index :purchases, :status
  end
end
```

```bash
rails db:migrate
```

### 3. モデルの実装

```ruby
# app/models/mock_test.rb
class MockTest < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_error
  has_many :purchasers, through: :purchases, source: :user
  
  validates :title, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :difficulty, inclusion: { in: %w[easy medium hard] }
  
  scope :published, -> { where(published: true) }
  
  def price_in_yen
    price_cents / 100
  end
  
  def purchased_by?(user)
    return false unless user
    purchases.where(user: user, status: 'completed').exists?
  end
end
```

```ruby
# app/models/purchase.rb
class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :mock_test
  
  enum status: {
    pending: 'pending',
    completed: 'completed',
    failed: 'failed',
    refunded: 'refunded'
  }, _prefix: true
  
  validates :user_id, uniqueness: { scope: :mock_test_id, message: "この模擬試験は既に購入済みです" }
  validates :amount_cents, presence: true
  
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }
end
```

```ruby
# app/models/user.rb に追加
has_many :purchases, dependent: :destroy
has_many :purchased_mock_tests, through: :purchases, source: :mock_test

def purchased?(mock_test)
  purchases.status_completed.exists?(mock_test: mock_test)
end
```

### 4. コントローラー作成

```bash
rails generate controller MockTests index show
rails generate controller Purchases new success cancel
```

```ruby
# app/controllers/mock_tests_controller.rb
class MockTestsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  
  def index
    @mock_tests = MockTest.published.order(created_at: :desc)
  end
  
  def show
    @mock_test = MockTest.find(params[:id])
    @purchased = current_user&.purchased?(@mock_test)
  end
  
  def take
    @mock_test = MockTest.find(params[:id])
    
    unless current_user.purchased?(@mock_test)
      redirect_to @mock_test, alert: 'この模擬試験を受験するには購入が必要です'
      return
    end
    
    # 受験画面を表示（Phase 6で実装）
    render :take
  end
end
```

```ruby
# app/controllers/purchases_controller.rb
class PurchasesController < ApplicationController
  before_action :authenticate_user!
  
  def new
    @mock_test = MockTest.find(params[:mock_test_id])
    
    # 重複購入チェック
    if current_user.purchased?(@mock_test)
      redirect_to @mock_test, alert: 'この模擬試験は既に購入済みです'
      return
    end
    
    # Purchase レコード作成
    purchase = current_user.purchases.create!(
      mock_test: @mock_test,
      amount_cents: @mock_test.price_cents,
      currency: 'jpy',
      status: 'pending'
    )
    
    # Stripe Checkout Session作成
    session = Stripe::Checkout::Session.create({
      mode: 'payment',
      line_items: [{
        price_data: {
          currency: 'jpy',
          product_data: {
            name: @mock_test.title,
            description: @mock_test.description
          },
          unit_amount: @mock_test.price_cents
        },
        quantity: 1
      }],
      metadata: {
        purchase_id: purchase.id,
        user_id: current_user.id,
        mock_test_id: @mock_test.id
      },
      customer_email: current_user.email,
      success_url: purchase_success_url(session_id: '{CHECKOUT_SESSION_ID}'),
      cancel_url: purchase_cancel_url
    })
    
    purchase.update!(stripe_checkout_session_id: session.id)
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to mock_tests_path, alert: "エラーが発生しました: #{e.message}"
  end
  
  def success
    redirect_to dashboard_path, notice: '模擬試験の購入が完了しました！'
  end
  
  def cancel
    redirect_to mock_tests_path, alert: '購入をキャンセルしました'
  end
end
```

### 5. Webhook処理の追加

```ruby
# app/controllers/webhooks/stripe_controller.rb に追加

def create
  # ... 既存のコード ...
  
  case event.type
  when 'checkout.session.completed'
    handle_checkout_completed(event.data.object)
  # ... 既存のイベント処理 ...
  end
  
  head :ok
end

private

def handle_checkout_completed(checkout_session)
  # サブスクリプションの場合はスキップ
  return if checkout_session.mode == 'subscription'
  
  # 模擬試験購入の場合
  purchase_id = checkout_session.metadata['purchase_id']
  purchase = Purchase.find_by(id: purchase_id)
  
  unless purchase
    Rails.logger.error "Purchase not found: #{purchase_id}"
    return
  end
  
  purchase.update!(
    status: 'completed',
    stripe_payment_intent_id: checkout_session.payment_intent
  )
  
  # メール送信（Phase 5で実装）
  # PurchaseMailer.purchase_completed(purchase).deliver_later
  
  Rails.logger.info "Purchase completed: #{purchase.id}"
end
```

### 6. ビューの作成

```erb
<!-- app/views/mock_tests/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-8">模擬試験一覧</h1>
  
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <% @mock_tests.each do |mock_test| %>
      <div class="border rounded-lg p-6 shadow-sm hover:shadow-md transition">
        <h2 class="text-xl font-semibold mb-2"><%= mock_test.title %></h2>
        <p class="text-gray-600 mb-4 line-clamp-3"><%= mock_test.description %></p>
        
        <div class="flex justify-between items-center mb-4">
          <span class="text-2xl font-bold">¥<%= number_with_delimiter(mock_test.price_in_yen) %></span>
          <span class="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
            <%= mock_test.difficulty %>
          </span>
        </div>
        
        <% if user_signed_in? %>
          <% if current_user.purchased?(mock_test) %>
            <%= link_to "受験する", take_mock_test_path(mock_test), 
                class: "block w-full bg-green-600 text-white text-center py-2 px-4 rounded hover:bg-green-700" %>
          <% else %>
            <%= link_to "購入する", new_purchase_path(mock_test_id: mock_test.id), 
                class: "block w-full bg-blue-600 text-white text-center py-2 px-4 rounded hover:bg-blue-700" %>
          <% end %>
        <% else %>
          <%= link_to "ログインして購入", new_user_session_path, 
              class: "block w-full bg-gray-600 text-white text-center py-2 px-4 rounded hover:bg-gray-700" %>
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

### 7. ダッシュボードに購入済み試験を表示

```erb
<!-- app/views/dashboard/index.html.erb に追加 -->

<!-- 購入済み模擬試験 -->
<div class="bg-white shadow rounded-lg p-6 mb-6">
  <h2 class="text-xl font-semibold mb-4">購入済み模擬試験</h2>
  
  <% if current_user.purchased_mock_tests.any? %>
    <div class="space-y-3">
      <% current_user.purchased_mock_tests.each do |mock_test| %>
        <div class="border rounded p-4 flex justify-between items-center">
          <div>
            <h3 class="font-semibold"><%= mock_test.title %></h3>
            <p class="text-sm text-gray-600">制限時間: <%= mock_test.time_limit_minutes %>分</p>
          </div>
          <%= link_to "受験する", take_mock_test_path(mock_test), 
              class: "bg-green-600 text-white py-2 px-6 rounded hover:bg-green-700" %>
        </div>
      <% end %>
    </div>
  <% else %>
    <p class="text-gray-600">まだ模擬試験を購入していません。</p>
    <%= link_to "模擬試験一覧を見る", mock_tests_path, class: "text-blue-600 underline" %>
  <% end %>
</div>
```

### 8. サンプルデータ作成

```ruby
# db/seeds.rb
# 管理者ユーザー
User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.confirmed_at = Time.current
end

# 模擬試験サンプル
MockTest.find_or_create_by!(title: 'TOEFL 模擬試験 Vol.1') do |test|
  test.description = '本番同様の4セクション総合試験。Reading, Listening, Speaking, Writingの全セクションを収録。'
  test.price_cents = 3000_00
  test.difficulty = 'medium'
  test.time_limit_minutes = 180
  test.published = true
end

MockTest.find_or_create_by!(title: 'TOEFL 模擬試験 Vol.2（上級）') do |test|
  test.description = '上級者向けの高難易度問題集。本番よりやや難しめの問題で実力をテスト。'
  test.price_cents = 3500_00
  test.difficulty = 'hard'
  test.time_limit_minutes = 180
  test.published = true
end
```

```bash
rails db:seed
```

### 9. ルーティング更新

```ruby
# config/routes.rb
resources :mock_tests, only: [:index, :show] do
  member do
    get :take
  end
end

resources :purchases, only: [:new] do
  collection do
    get :success
    get :cancel
  end
end
```

## Phase 5: メール通知機能

### 1. メーラー作成

```bash
rails generate mailer Purchase purchase_completed
rails generate mailer Subscription trial_started subscription_activated payment_failed canceled
```

### 2. PurchaseMailer実装

```ruby
# app/mailers/purchase_mailer.rb
class PurchaseMailer < ApplicationMailer
  def purchase_completed(purchase)
    @purchase = purchase
    @user = purchase.user
    @mock_test = purchase.mock_test
    
    mail(
      to: @user.email,
      subject: "【TOEFL学習】#{@mock_test.title} の購入が完了しました"
    )
  end
end
```

```erb
<!-- app/views/purchase_mailer/purchase_completed.html.erb -->
<h2>購入が完了しました</h2>

<p><%= @user.email %> 様</p>

<p>以下の模擬試験の購入が完了しました。</p>

<div style="background: #f3f4f6; padding: 20px; margin: 20px 0; border-radius: 8px;">
  <h3><%= @mock_test.title %></h3>
  <p><strong>金額:</strong> ¥<%= number_with_delimiter(@purchase.amount_cents / 100) %></p>
  <p><strong>購入日時:</strong> <%= @purchase.created_at.strftime('%Y年%m月%d日 %H:%M') %></p>
</div>

<p>
  <%= link_to "受験する", take_mock_test_url(@mock_test), 
      style: "background: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;" %>
</p>

<p style="color: #6b7280; font-size: 14px;">
  購入した模擬試験は、ダッシュボードからいつでもアクセスできます。
</p>
```

### 3. SubscriptionMailer実装

```ruby
# app/mailers/subscription_mailer.rb
class SubscriptionMailer < ApplicationMailer
  def trial_started(user)
    @user = user
    @trial_ends_at = user.subscription.trial_ends_at
    
    mail(
      to: @user.email,
      subject: '【TOEFL学習】7日間無料トライアルを開始しました'
    )
  end
  
  def subscription_activated(user)
    @user = user
    @subscription = user.subscription
    
    mail(
      to: @user.email,
      subject: '【TOEFL学習】有料プランが開始されました'
    )
  end
  
  def payment_failed(user)
    @user = user
    @subscription = user.subscription
    
    mail(
      to: @user.email,
      subject: '【重要】お支払いに失敗しました'
    )
  end
  
  def canceled(user)
    @user = user
    @subscription = user.subscription
    @ends_at = @subscription.ends_at
    
    mail(
      to: @user.email,
      subject: '【TOEFL学習】サブスクリプションを解約しました'
    )
  end
end
```

### 4. メールテンプレート

```erb
<!-- app/views/subscription_mailer/trial_started.html.erb -->
<h2>7日間無料トライアルへようこそ！</h2>

<p><%= @user.email %> 様</p>

<p>7日間の無料トライアルが開始されました。今すぐすべてのセクション別演習にアクセスできます。</p>

<div style="background: #f3f4f6; padding: 20px; margin: 20px 0; border-radius: 8px;">
  <h3>トライアル期間</h3>
  <p><strong>開始日:</strong> <%= Time.current.strftime('%Y年%m月%d日') %></p>
  <p><strong>終了日:</strong> <%= @trial_ends_at.strftime('%Y年%m月%d日') %></p>
  <p>トライアル終了後、自動的に有料プラン（月額2,980円）へ移行します。</p>
</div>

<p>
  <%= link_to "ダッシュボードへ", dashboard_url, 
      style: "background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;" %>
</p>
```

### 5. Webhookでのメール送信

```ruby
# app/controllers/webhooks/stripe_controller.rb

def handle_subscription_created(stripe_subscription)
  # ... 既存のコード ...
  
  if subscription.save
    SubscriptionMailer.trial_started(user).deliver_later if subscription.status_trial?
  end
end

def handle_checkout_completed(checkout_session)
  # ... 既存のコード ...
  
  purchase.update!(
    status: 'completed',
    stripe_payment_intent_id: checkout_session.payment_intent
  )
  
  PurchaseMailer.purchase_completed(purchase).deliver_later
end

def handle_payment_succeeded(invoice)
  # ... 既存のコード ...
  
  if subscription.status_trial? && invoice.billing_reason == 'subscription_cycle'
    subscription.update!(status: 'active')
    SubscriptionMailer.subscription_activated(subscription.user).deliver_later
  end
end

def handle_payment_failed(invoice)
  # ... 既存のコード ...
  
  subscription.update!(status: 'past_due')
  SubscriptionMailer.payment_failed(subscription.user).deliver_later
end

def handle_subscription_deleted(stripe_subscription)
  # ... 既存のコード ...
  
  subscription.update!(
    status: 'canceled',
    canceled_at: Time.current,
    ends_at: Time.at(stripe_subscription.current_period_end)
  )
  
  SubscriptionMailer.canceled(subscription.user).deliver_later
end
```

### 6. 本番環境用SendGrid設定

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_url_options = { host: 'yourdomain.com', protocol: 'https' }

config.action_mailer.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: 587,
  domain: 'yourdomain.com',
  authentication: :plain,
  user_name: 'apikey',
  password: ENV['SENDGRID_API_KEY'],
  enable_starttls_auto: true
}

config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
```

## 動作確認

### 模擬試験購入フロー

1. `http://localhost:3000/mock_tests` にアクセス
2. 模擬試験を選択
3. 「購入する」をクリック
4. テストカード番号 `4242 4242 4242 4242` で決済
5. Webhookイベント確認（Stripe CLI）
6. 購入完了メールが開く（letter_opener）
7. ダッシュボードに購入済み試験が表示される

### メール確認

開発環境では`http://localhost:3000/letter_opener`でメール一覧を確認できます。

## 確認ポイント

- [ ] MockTest, Purchaseモデルが作成されている
- [ ] 模擬試験一覧が表示される
- [ ] 購入フローが正常に動作する
- [ ] 重複購入が防止されている
- [ ] 購入完了メールが送信される
- [ ] サブスクリプション関連メールが送信される
- [ ] ダッシュボードに購入済み試験が表示される

## トラブルシューティング

### メールが送信されない

開発環境の設定を確認：
```ruby
config.action_mailer.perform_deliveries = true
```

### 重複購入エラー

uniqueインデックスが正しく設定されているか確認：
```bash
rails db:migrate:status
```

## 次のステップ

Phase 4-5完了後は、UI/UXの改善や本番環境へのデプロイを検討してください。

追加で実装可能な機能：
- 受験機能の実装
- 成績管理システム
- 学習進捗トラッキング
- モバイル対応の強化

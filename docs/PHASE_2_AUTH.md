# Phase 2: ユーザー認証機能（Devise）

## 目標

Deviseを使用したユーザー認証システムを実装する。サインアップ、ログイン、メール確認機能を含む。

## 実装手順

### 1. Deviseのインストール

```bash
# Devise設定ファイル生成
rails generate devise:install
```

### 2. Devise設定の調整

`config/initializers/devise.rb`を編集：

```ruby
# config/initializers/devise.rb

# メール送信元アドレス
config.mailer_sender = 'noreply@yourdomain.com'

# パスワード長
config.password_length = 8..128

# 確認メール有効期限（3日間）
config.confirm_within = 3.days

# セッションタイムアウト
config.timeout_in = 30.minutes
```

### 3. Userモデル作成

```bash
# Confirmableモジュール付きでUserモデル生成
rails generate devise User
```

生成されたマイグレーションファイルを編集し、Confirmableを有効化：

```ruby
# db/migrate/xxxxxx_devise_create_users.rb
class DeviseCreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable - コメントアウトを解除
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
  end
end
```

### 4. Userモデルの設定

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # 将来の関連付け（後のPhaseで追加）
  # has_one :subscription, dependent: :destroy
  # has_many :purchases, dependent: :destroy
end
```

### 5. マイグレーション実行

```bash
rails db:migrate
```

### 6. ルーティング設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  
  # カスタムルート（オプション）
  devise_scope :user do
    get 'signup', to: 'devise/registrations#new'
    get 'login', to: 'devise/sessions#new'
    delete 'logout', to: 'devise/sessions#destroy'
  end
  
  # 認証済みユーザーのルート
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  root 'pages#home'
end
```

### 7. ダッシュボードコントローラー作成

```bash
rails generate controller Dashboard index
```

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user = current_user
  end
end
```

### 8. Deviseビューのカスタマイズ

```bash
# Deviseのビューを生成
rails generate devise:views
```

### 9. ナビゲーションメニュー作成

`app/views/layouts/application.html.erb`にナビゲーションを追加：

```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>TOEFL Platform</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <!-- ナビゲーションバー -->
    <nav class="bg-blue-600 text-white p-4">
      <div class="container mx-auto flex justify-between items-center">
        <div class="text-xl font-bold">
          <%= link_to "TOEFL Platform", root_path, class: "hover:text-blue-200" %>
        </div>
        
        <div class="space-x-4">
          <% if user_signed_in? %>
            <%= link_to "ダッシュボード", dashboard_path, class: "hover:text-blue-200" %>
            <%= link_to "ログアウト", destroy_user_session_path, 
                data: { turbo_method: :delete }, 
                class: "hover:text-blue-200" %>
          <% else %>
            <%= link_to "ログイン", new_user_session_path, class: "hover:text-blue-200" %>
            <%= link_to "新規登録", new_user_registration_path, class: "bg-white text-blue-600 px-4 py-2 rounded hover:bg-blue-50" %>
          <% end %>
        </div>
      </div>
    </nav>
    
    <!-- フラッシュメッセージ -->
    <% if notice.present? %>
      <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative m-4" role="alert">
        <%= notice %>
      </div>
    <% end %>
    
    <% if alert.present? %>
      <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative m-4" role="alert">
        <%= alert %>
      </div>
    <% end %>
    
    <!-- メインコンテンツ -->
    <%= yield %>
  </body>
</html>
```

### 10. サインアップフォームのカスタマイズ

```erb
<!-- app/views/devise/registrations/new.html.erb -->
<div class="container mx-auto px-4 py-8 max-w-md">
  <h2 class="text-3xl font-bold mb-6">新規登録</h2>

  <%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { class: "space-y-4" }) do |f| %>
    <%= render "devise/shared/error_messages", resource: resource %>

    <div>
      <%= f.label :email, "メールアドレス", class: "block text-sm font-medium text-gray-700" %>
      <%= f.email_field :email, autofocus: true, autocomplete: "email", 
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>

    <div>
      <%= f.label :password, "パスワード", class: "block text-sm font-medium text-gray-700" %>
      <% if @minimum_password_length %>
        <span class="text-sm text-gray-500">(<%= @minimum_password_length %>文字以上)</span>
      <% end %>
      <%= f.password_field :password, autocomplete: "new-password", 
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>

    <div>
      <%= f.label :password_confirmation, "パスワード（確認）", class: "block text-sm font-medium text-gray-700" %>
      <%= f.password_field :password_confirmation, autocomplete: "new-password", 
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>

    <div>
      <%= f.submit "登録", class: "w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 font-medium" %>
    </div>
  <% end %>

  <div class="mt-6 text-center">
    <%= render "devise/shared/links" %>
  </div>
</div>
```

### 11. ログインフォームのカスタマイズ

```erb
<!-- app/views/devise/sessions/new.html.erb -->
<div class="container mx-auto px-4 py-8 max-w-md">
  <h2 class="text-3xl font-bold mb-6">ログイン</h2>

  <%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { class: "space-y-4" }) do |f| %>
    <div>
      <%= f.label :email, "メールアドレス", class: "block text-sm font-medium text-gray-700" %>
      <%= f.email_field :email, autofocus: true, autocomplete: "email", 
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>

    <div>
      <%= f.label :password, "パスワード", class: "block text-sm font-medium text-gray-700" %>
      <%= f.password_field :password, autocomplete: "current-password", 
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>

    <% if devise_mapping.rememberable? %>
      <div class="flex items-center">
        <%= f.check_box :remember_me, class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" %>
        <%= f.label :remember_me, "ログイン状態を保持", class: "ml-2 block text-sm text-gray-900" %>
      </div>
    <% end %>

    <div>
      <%= f.submit "ログイン", class: "w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 font-medium" %>
    </div>
  <% end %>

  <div class="mt-6 text-center">
    <%= render "devise/shared/links" %>
  </div>
</div>
```

### 12. ダッシュボードビュー

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-8">ダッシュボード</h1>
  
  <div class="bg-white shadow rounded-lg p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">アカウント情報</h2>
    <p class="text-gray-700">メールアドレス: <%= @user.email %></p>
    <p class="text-gray-700">登録日: <%= @user.created_at.strftime('%Y年%m月%d日') %></p>
  </div>
  
  <div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
    <h2 class="text-xl font-semibold mb-4 text-blue-800">次のステップ</h2>
    <p class="text-blue-700">Phase 3でサブスクリプション機能を追加します。</p>
  </div>
</div>
```

### 13. 日本語化（オプション）

```ruby
# config/application.rb
module ToeflPlatform
  class Application < Rails::Application
    config.load_defaults 7.0
    config.i18n.default_locale = :ja
  end
end
```

`config/locales/devise.ja.yml`を作成（Deviseの日本語訳）：
※ https://github.com/tigrish/devise-i18n からダウンロード可能

### 14. テストの作成

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end
  
  describe 'devise modules' do
    it 'has confirmable module' do
      expect(User.devise_modules).to include(:confirmable)
    end
  end
end
```

```bash
# テスト実行
bundle exec rspec
```

## 動作確認

### 1. サーバー起動

```bash
bin/dev
```

### 2. テストフロー

1. `http://localhost:3000` にアクセス
2. 「新規登録」ボタンをクリック
3. メールアドレスとパスワードを入力
4. 登録後、確認メールが開く（letter_opener）
5. メール内のリンクをクリック
6. 自動的にログインされ、ダッシュボードに遷移

### 3. ログアウト・ログインテスト

1. ダッシュボードから「ログアウト」
2. 「ログイン」から再度ログイン
3. ダッシュボードに戻ることを確認

## 確認ポイント

- [ ] Deviseが正しくインストールされている
- [ ] Userモデルが作成され、Confirmableが有効
- [ ] サインアップフォームが動作する
- [ ] 確認メールが送信される（letter_openerで確認）
- [ ] メール確認後、自動ログインされる
- [ ] ログイン/ログアウトが正常に動作する
- [ ] ダッシュボードが表示される
- [ ] ナビゲーションメニューが正しく表示される

## トラブルシューティング

### 確認メールが開かない

開発環境のメール設定を確認：
```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

### ログイン後にリダイレクトされない

`ApplicationController`にメソッドを追加：
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource)
    dashboard_path
  end
end
```

## 次のフェーズ

Phase 2が完了したら、Phase 3（サブスクリプション機能）に進んでください。

```
Phase 3: Stripe Billingによるサブスクリプション機能の実装
- Subscriptionモデル作成
- 無料トライアル機能
- Stripe Checkout統合
- Webhook処理
```

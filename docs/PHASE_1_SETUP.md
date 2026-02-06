# Phase 1: プロジェクト初期セットアップ

## 目標

Rails 7プロジェクトの作成、基本Gemのインストール、データベース設定を完了させる。

## 実装手順

### 1. Railsプロジェクト作成

```bash
# PostgreSQLを使用してRailsプロジェクト作成
rails new toefl_platform --database=postgresql --css=tailwind

cd toefl_platform
```

### 2. Gemfileの設定

以下のGemを`Gemfile`に追加してください：

```ruby
# Gemfile

# 認証
gem 'devise'

# 決済
gem 'stripe'

# 環境変数管理
gem 'dotenv-rails', groups: [:development, :test]

# ファイルストレージ
gem 'aws-sdk-s3', require: false

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
end

group :development do
  gem 'letter_opener'
end

group :test do
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
end
```

### 3. Gemインストール

```bash
bundle install
```

### 4. データベース設定

```bash
# データベース作成
rails db:create
```

### 5. 環境変数ファイル作成

`.env`ファイルを作成し、以下の内容を追加：

```bash
# .env
# Stripe (テストモード)
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_secret_here
STRIPE_SUBSCRIPTION_PRICE_ID=price_your_price_id_here

# SendGrid
SENDGRID_API_KEY=your_sendgrid_api_key_here

# AWS S3 (本番環境用 - 開発時は後で設定)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-northeast-1
AWS_S3_BUCKET=
```

### 6. .gitignoreに追加

```bash
# .gitignore に以下を追加
/.env
/.env.*
!/.env.example
```

### 7. Stripe初期化設定

`config/initializers/stripe.rb`を作成：

```ruby
# config/initializers/stripe.rb
Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key: ENV['STRIPE_SECRET_KEY'],
  webhook_secret: ENV['STRIPE_WEBHOOK_SECRET']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
```

### 8. RSpec設定

```bash
# RSpecインストール
rails generate rspec:install
```

`spec/rails_helper.rb`に以下を追加：

```ruby
# spec/rails_helper.rb

# Shoulda Matchers設定
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# FactoryBot設定
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

### 9. Letter Opener設定（開発環境）

```ruby
# config/environments/development.rb
Rails.application.configure do
  # ... 既存の設定 ...
  
  # メール設定
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.perform_deliveries = true
end
```

### 10. 基本ページの作成

```bash
# ホームページコントローラー作成
rails generate controller Pages home
```

`config/routes.rb`を編集：

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root 'pages#home'
end
```

### 11. Tailwind CSS の確認

```bash
# Tailwind CSSのビルド確認
rails tailwindcss:build
```

### 12. サーバー起動確認

```bash
# サーバー起動
bin/dev

# または
rails server
```

ブラウザで `http://localhost:3000` にアクセスし、ホームページが表示されることを確認。

## 確認ポイント

- [ ] Railsプロジェクトが作成されている
- [ ] PostgreSQLデータベースが作成されている
- [ ] 必要なGemがインストールされている
- [ ] 環境変数ファイル(.env)が作成されている
- [ ] Stripeの初期化設定が完了している
- [ ] RSpecが正しくセットアップされている
- [ ] 開発サーバーが起動し、ホームページが表示される

## トラブルシューティング

### データベース接続エラー

PostgreSQLが起動していることを確認：
```bash
# macOS (Homebrew)
brew services start postgresql

# Linux (systemd)
sudo systemctl start postgresql
```

### Tailwind CSSが反映されない

```bash
# Tailwind CSSを再ビルド
rails tailwindcss:build
```

## 次のフェーズ

Phase 1が完了したら、Phase 2（認証機能実装）に進んでください。

```
Phase 2: Deviseによるユーザー認証機能の実装
- ユーザーモデル作成
- サインアップ/ログイン機能
- メール確認機能
```

# TOEFL学習プラットフォーム - クイックスタートガイド

## 📚 このドキュメントセットについて

このドキュメントセットは、TOEFL試験対策オンライン学習プラットフォームを段階的に実装するための完全なガイドです。

## 🎯 システム概要

- **サブスクリプション制**: セクション別演習（Reading, Listening, Speaking, Writing）
- **単発購入制**: 模擬試験（本番同様の総合試験）
- **7日間無料トライアル**: 新規ユーザー向け
- **自動課金**: Stripe Billingによる月額課金
- **決済管理**: Stripe Customer Portalでユーザー自身が管理

## 📖 ドキュメント構成

### 基本設計ドキュメント（必読）

1. **01_PROJECT_OVERVIEW.md** - プロジェクト全体像とビジネスモデル
2. **02_DATABASE_SCHEMA.md** - データベース設計とER図
3. **03_TECHNICAL_STACK.md** - 技術スタックと選定理由

### 機能別実装ガイド

4. **04_AUTHENTICATION.md** - Deviseによるユーザー認証
5. **05_SUBSCRIPTION.md** - Stripe Billingでサブスクリプション機能
6. **06_MOCK_TEST_PURCHASE.md** - 模擬試験の単発購入機能
7. **07_EMAIL_NOTIFICATIONS.md** - SendGridによるメール通知
8. **08_STRIPE_INTEGRATION.md** - Stripe連携の詳細とWebhook処理

### Antigravity用実装プロンプト（コピペ可能）

`prompts/` ディレクトリ内:

- **PHASE_1_SETUP.md** - Railsプロジェクト初期セットアップ
- **PHASE_2_AUTH.md** - 認証機能実装（Devise）
- **PHASE_3_SUBSCRIPTION.md** - サブスクリプション機能実装
- **PHASE_4_5_PURCHASE_EMAIL.md** - 模擬試験購入とメール通知

## 🚀 実装の進め方

### ステップ1: 環境準備

必要なもの:
- Ruby 3.1以上
- Rails 7.0以上
- PostgreSQL 14以上
- Node.js 18以上（Tailwind CSS用）
- Stripeアカウント（テストモード）
- SendGridアカウント（無料プラン可）

### ステップ2: 段階的実装

各Phaseを順番に実装してください：

```
Phase 1（30分）
  ↓ Railsプロジェクト作成、Gem導入
Phase 2（1-2時間）
  ↓ ユーザー認証、ダッシュボード
Phase 3（2-3時間）
  ↓ サブスクリプション機能、無料トライアル
Phase 4-5（2-3時間）
  ↓ 模擬試験購入、メール通知
完成！（合計6-9時間）
```

### ステップ3: Antigravityでの使い方

1. `prompts/PHASE_1_SETUP.md` の内容をAntigravityにコピー
2. 指示に従ってコマンドを実行
3. 確認ポイントをチェック
4. 次のPhaseへ進む

各プロンプトには以下が含まれます:
- 実装する機能の詳細
- コマンドとコード例
- 動作確認方法
- トラブルシューティング

## 💡 重要なポイント

### Stripeの設定

```bash
# .env ファイルに以下を設定
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_SUBSCRIPTION_PRICE_ID=price_xxx
```

### Webhook のローカルテスト

```bash
# Stripe CLIでWebhookをフォワード
stripe listen --forward-to localhost:3000/webhooks/stripe
```

### テストカード番号

```
成功: 4242 4242 4242 4242
失敗: 4000 0000 0000 0002
```

## 📝 各Phaseの確認ポイント

### Phase 1
- [ ] Railsプロジェクトが起動する
- [ ] PostgreSQLに接続できる
- [ ] Tailwind CSSが動作する

### Phase 2
- [ ] ユーザー登録ができる
- [ ] 確認メールが届く（letter_opener）
- [ ] ログイン/ログアウトできる
- [ ] ダッシュボードが表示される

### Phase 3
- [ ] 無料トライアルに登録できる
- [ ] Webhookイベントが処理される
- [ ] Customer Portalにアクセスできる
- [ ] サブスクリプション状態が表示される

### Phase 4-5
- [ ] 模擬試験が購入できる
- [ ] 重複購入が防止される
- [ ] 購入完了メールが届く
- [ ] ダッシュボードに購入済み試験が表示される

## 🔧 トラブルシューティング

### よくある問題

**データベース接続エラー**
```bash
brew services start postgresql  # macOS
sudo systemctl start postgresql # Linux
```

**Webhookが届かない**
```bash
# Stripe CLIが起動しているか確認
stripe listen --forward-to localhost:3000/webhooks/stripe
```

**メールが送信されない**
```ruby
# config/environments/development.rb
config.action_mailer.perform_deliveries = true
```

## 📚 参考リソース

- [Stripe公式ドキュメント](https://stripe.com/docs)
- [Devise GitHub](https://github.com/heartcombo/devise)
- [Rails Guides](https://guides.rubyonrails.org/)
- [SendGrid Ruby](https://github.com/sendgrid/sendgrid-ruby)

## 🎓 学習のヒント

1. **まず全体像を理解**: 01_PROJECT_OVERVIEW.md を読む
2. **データベースを理解**: 02_DATABASE_SCHEMA.md でテーブル関係を把握
3. **段階的に実装**: 一度に全部やらず、1 Phaseずつ確実に
4. **テストを忘れずに**: 各Phaseの確認ポイントを必ずチェック
5. **Webhookを理解**: 08_STRIPE_INTEGRATION.md でStripeの仕組みを学ぶ

## 🚀 次のステップ

Phase 1-5完了後の拡張可能性:
- 受験機能の実装（タイマー、自動採点）
- 成績分析ダッシュボード
- 学習進捗トラッキング
- AI による弱点診断
- モバイルアプリ化

## 📞 サポート

実装中に問題が発生した場合:
1. 該当Phaseの「トラブルシューティング」セクションを確認
2. Stripeダッシュボードでイベントログを確認
3. Railsログを確認: `tail -f log/development.log`

---

**準備はいいですか？**

まずは `prompts/PHASE_1_SETUP.md` を開いて、実装を始めましょう！

Good luck! 🎉

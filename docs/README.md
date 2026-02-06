# TOEFL試験対策プラットフォーム 実装ドキュメント

## 概要

このドキュメントセットは、TOEFL試験対策オンライン学習プラットフォームの段階的実装のために作成されています。

### システム概要

- **セクション別演習**: サブスクリプション制（月額課金）
- **模擬試験**: 単発購入制
- **技術スタック**: Ruby on Rails, PostgreSQL, Stripe, Devise, SendGrid, Tailwind CSS

## ドキュメント構成

### 1. 基本設計ドキュメント
- `01_PROJECT_OVERVIEW.md` - プロジェクト全体像
- `02_DATABASE_SCHEMA.md` - データベース設計
- `03_TECHNICAL_STACK.md` - 技術選定と理由

### 2. 機能別実装ガイド
- `04_AUTHENTICATION.md` - 認証機能（Devise）
- `05_SUBSCRIPTION.md` - サブスクリプション機能
- `06_MOCK_TEST_PURCHASE.md` - 模擬試験購入機能
- `07_EMAIL_NOTIFICATIONS.md` - メール通知機能
- `08_STRIPE_INTEGRATION.md` - Stripe連携詳細

### 3. 実装プロンプト（Antigravity用）
- `prompts/PHASE_1_SETUP.md` - 初期セットアップ
- `prompts/PHASE_2_AUTH.md` - 認証機能実装
- `prompts/PHASE_3_SUBSCRIPTION.md` - サブスクリプション実装
- `prompts/PHASE_4_PURCHASE.md` - 模擬試験購入実装
- `prompts/PHASE_5_EMAIL.md` - メール機能実装
- `prompts/PHASE_6_UI.md` - UI/UX実装

### 4. 補足資料
- `DEPLOYMENT.md` - デプロイメントガイド
- `TESTING.md` - テスト戦略
- `TROUBLESHOOTING.md` - よくある問題と解決方法

## 推奨実装順序

1. **Phase 1**: プロジェクトセットアップ（Rails, DB, 基本Gem）
2. **Phase 2**: 認証機能（Devise）
3. **Phase 3**: サブスクリプション機能（Stripe Billing）
4. **Phase 4**: 模擬試験購入機能（Stripe Checkout）
5. **Phase 5**: メール通知機能（SendGrid）
6. **Phase 6**: UI/UX改善（Tailwind CSS）

## 使い方

各フェーズのプロンプトファイルを順番にAntigravityに入力してください。各プロンプトには以下が含まれます：

- 実装する機能の詳細説明
- 必要なファイルとコード
- テスト方法
- 次のフェーズへの準備

## 注意事項

- Stripeのテストモードキーを使用してください
- 本番環境への移行前に、すべての決済フローをテストしてください
- 環境変数は`.env`ファイルで管理し、`.gitignore`に追加してください

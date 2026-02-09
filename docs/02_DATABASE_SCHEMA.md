# 02_DATABASE_SCHEMA.md

## 目的

この設計は、サブスクリプションを **`trial` / `premium` の2プランのみ** で運用する前提です。  
`users` に対して `subscriptions` は1:1で保持し、現在の契約状態を1レコードで管理します。

## 確定仕様

- `plan` は `trial` / `premium` の2種類
- `status` は最小構成として `active` / `past_due` / `canceled` の3種類
- サブスクリプション変更ログ用の履歴テーブルは作成しない

## ER 関係

```text
users (1) ---- (1) subscriptions
users (1) ---- (N) user_exams (N) ---- (1) exams
```

## テーブル一覧

### 1. `users`（既存）
- 認証情報（Devise）を保持
- 主キー: `id`

### 2. `exams`（既存）
- 単発購入される模擬試験マスタ
- 主キー: `id`

### 3. `user_exams`（既存）
- ユーザーの模擬試験購入履歴
- 外部キー: `user_id` -> `users.id`
- 外部キー: `exam_id` -> `exams.id`
- 一意制約: `(user_id, exam_id)`

### 4. `subscriptions`（新規）
- サブスク契約の現在状態
- 外部キー: `user_id` -> `users.id`
- 一意制約: `user_id`（1ユーザー1契約）

## `subscriptions` カラム定義

| カラム名 | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `id` | bigint | yes | - | 主キー |
| `user_id` | bigint | yes | - | ユーザーID（ユニーク） |
| `plan` | string | yes | `trial` | プラン種別（`trial` / `premium`） |
| `status` | string | yes | `active` | 契約状態（`active` / `past_due` / `canceled`） |
| `stripe_customer_id` | string | no | - | Stripe Customer ID |
| `stripe_subscription_id` | string | no | - | Stripe Subscription ID |
| `stripe_price_id` | string | no | - | Stripe Price ID |
| `trial_started_at` | datetime | no | - | トライアル開始日時 |
| `trial_ends_at` | datetime | no* | - | トライアル終了日時（`plan=trial`時は必須） |
| `current_period_start` | datetime | no | - | 現在課金期間開始 |
| `current_period_end` | datetime | no | - | 現在課金期間終了 |
| `cancel_at_period_end` | boolean | yes | `false` | 期間終了時解約フラグ |
| `canceled_at` | datetime | no | - | 解約確定日時 |
| `ends_at` | datetime | no | - | 実際の利用終了日時 |
| `created_at` | datetime | yes | - | 作成日時 |
| `updated_at` | datetime | yes | - | 更新日時 |

## 制約・インデックス

- `plan IN ('trial', 'premium')`
- `status IN ('active', 'past_due', 'canceled')`
- `plan = 'trial'` の場合は `trial_ends_at IS NOT NULL`
- `user_id` ユニークインデックス
- `stripe_customer_id` ユニーク部分インデックス（`IS NOT NULL`）
- `stripe_subscription_id` ユニーク部分インデックス（`IS NOT NULL`）
- `plan`, `status` の検索用インデックス

## 状態遷移（運用想定）

1. 新規登録時: `plan=trial, status=active`
2. トライアル課金成功後: `plan=premium, status=active`
3. 支払い失敗時: `status=past_due`
4. 解約時: `status=canceled`（必要に応じて `ends_at` を設定）

## 設計意図

- プラン種別を2値に固定することで、UI/決済分岐を単純化。
- 契約の「現在状態」を1行で持つことで、判定クエリを高速化。
- Stripe IDは将来のWebhook再処理・照合を考慮して保持。

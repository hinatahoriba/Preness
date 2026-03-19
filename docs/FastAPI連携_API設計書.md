# FastAPI連携 API設計書

## 概要

FastAPIからRails APIへPOSTリクエストでコンテンツ（模擬試験・演習問題）を登録するための設計書。

---

## 認証

すべてのAPIリクエストに `Authorization` ヘッダーが必要。

```
Authorization: Bearer <CONTENT_SOURCE_API_KEY>
```

サーバー側の環境変数 `CONTENT_SOURCE_API_KEY` と照合される。

---

## エンドポイント一覧

| メソッド | パス | 説明 |
|---|---|---|
| POST | `/api/v1/mocks` | 模擬試験（Mock）を登録 |
| POST | `/api/v1/exercises` | 演習問題（Exercise）を登録 |

---

## 1. 模擬試験登録 API

### `POST /api/v1/mocks`

リスニング・ストラクチャー・リーディングの3セクションをまとめて1つの模擬試験として登録する。

#### データ構造

```
Mock
└── sections[] (listening / structure / reading の3つが必須)
    └── parts[]
        └── question_sets[]
            └── questions[]
```

#### リクエストボディ

```json
{
  "title": "模擬試験 Vol.1",
  "sections": [
    {
      "section_type": "listening",
      "display_order": 1,
      "parts": [
        {
          "part_type": "part_a",
          "display_order": 1,
          "question_sets": [
            {
              "display_order": 1,
              "conversation_audio_url": "https://example.com/audio/q1.mp3",
              "passage": null,
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "What did the man say?",
                  "question_audio_url": null,
                  "choice_a": "He is happy.",
                  "choice_b": "He is sad.",
                  "choice_c": "He is tired.",
                  "choice_d": "He is hungry.",
                  "correct_choice": "a",
                  "explanation": "会話中で男性は〜と述べている。",
                  "tag": "推測",
                  "wrong_reason_a": null,
                  "wrong_reason_b": "彼が悲しいとは述べていない。",
                  "wrong_reason_c": "疲れているとは言っていない。",
                  "wrong_reason_d": "空腹への言及はない。"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "section_type": "structure",
      "display_order": 2,
      "parts": [...]
    },
    {
      "section_type": "reading",
      "display_order": 3,
      "parts": [...]
    }
  ]
}
```

#### パラメータ詳細

**トップレベル**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `title` | string | ✅ | 模擬試験タイトル |
| `sections` | array | ✅ | セクション配列。`listening` / `structure` / `reading` の3つが必須 |

**sections[i]**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `section_type` | string | ✅ | `listening` / `structure` / `reading` |
| `display_order` | integer | ✅ | 表示順 |
| `parts` | array | ✅ | パート配列 |

**sections[i].parts[j]**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `part_type` | string | ✅ | `part_a` / `part_b` / `part_c` / `passages` |
| `display_order` | integer | ✅ | 表示順 |
| `question_sets` | array | ✅ | 問題セット配列 |

**question_sets[k]**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `display_order` | integer | ✅ | 表示順 |
| `passage` | string | - | リーディング用パッセージ本文 |
| `conversation_audio_url` | string | - | リスニング用会話音声URL |
| `questions` | array | ✅ | 設問配列 |

**questions[l]**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `display_order` | integer | ✅ | 表示順 |
| `question_text` | string | ✅ | 問題文 |
| `question_audio_url` | string | - | 設問音声URL |
| `choice_a` | string | ✅ | 選択肢A |
| `choice_b` | string | ✅ | 選択肢B |
| `choice_c` | string | ✅ | 選択肢C |
| `choice_d` | string | ✅ | 選択肢D |
| `correct_choice` | string | ✅ | 正解選択肢 (`a` / `b` / `c` / `d`) |
| `explanation` | string | - | 解説文（正解の理由） |
| `tag` | string | - | 問題タグ（例: `推測`, `詳細`, `主旨`） |
| `wrong_reason_a` | string | - | 選択肢Aの誤答理由 |
| `wrong_reason_b` | string | - | 選択肢Bの誤答理由 |
| `wrong_reason_c` | string | - | 選択肢Cの誤答理由 |
| `wrong_reason_d` | string | - | 選択肢Dの誤答理由 |

> **Note:** `wrong_reason_{正解選択肢}` は `null` でよい。

#### レスポンス

**成功 (201 Created)**

```json
{
  "status": "success",
  "mock_id": 1,
  "title": "模擬試験 Vol.1"
}
```

**バリデーションエラー (422 Unprocessable Entity)**

```json
{
  "status": "error",
  "errors": ["Validation failed: sections must include listening, structure, reading"]
}
```

**認証エラー (401 Unauthorized)**

```json
{
  "status": "error",
  "errors": ["Unauthorized"]
}
```

---

## 2. 演習問題登録 API

### `POST /api/v1/exercises`

特定のセクション・パートの問題セットをまとめて演習として登録する。
1つの `question_set` につき1つの `Exercise` レコードが作成される。

#### データ構造

```
Exercise (question_setごとに1件作成)
└── section (1件 / section_type・display_orderは自動決定)
    └── part (1件 / part_type・display_orderは自動決定)
        └── question_set (1件)
            └── questions[]
```

#### section_type × part_type の有効な組み合わせ

| section_type | 有効な part_type |
|---|---|
| `listening` | `part_a`, `part_b`, `part_c` |
| `structure` | `part_a`, `part_b` |
| `reading` | `passages` |

#### display_order の自動決定

section_typeとpart_typeのdisplay_orderはAPI側で自動設定される。

| section_type | section display_order |
|---|---|
| `listening` | 1 |
| `structure` | 2 |
| `reading` | 3 |

| part_type | part display_order |
|---|---|
| `part_a` | 1 |
| `part_b` | 2 |
| `part_c` | 3 |
| `passages` | 1 |

#### リクエストボディ

```json
{
  "section_type": "listening",
  "part_type": "part_a",
  "question_sets": [
    {
      "display_order": 1,
      "conversation_audio_url": "https://example.com/audio/q1.mp3",
      "passage": null,
      "questions": [
        {
          "display_order": 1,
          "question_text": "What does the woman suggest?",
          "question_audio_url": null,
          "choice_a": "She wants to leave.",
          "choice_b": "She prefers to stay.",
          "choice_c": "She is not sure.",
          "choice_d": "She disagrees.",
          "correct_choice": "b",
          "explanation": "女性は〜と述べており、滞在を希望していることがわかる。",
          "tag": "提案",
          "wrong_reason_a": "去りたいとは言っていない。",
          "wrong_reason_b": null,
          "wrong_reason_c": "確信がないとは述べていない。",
          "wrong_reason_d": "反対意見は述べていない。"
        }
      ]
    }
  ]
}
```

#### パラメータ詳細

**トップレベル**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `section_type` | string | ✅ | `listening` / `structure` / `reading` |
| `part_type` | string | ✅ | section_typeに応じた有効値 |
| `question_sets` | array | ✅ | 問題セット配列（1件以上必須） |

**question_sets[k]・questions[l]**
Mock登録APIの同名フィールドと同一仕様。

#### レスポンス

**成功 (201 Created)**

```json
{
  "status": "success",
  "exercise_ids": [1, 2, 3],
  "created_count": 3
}
```

**バリデーションエラー (422 Unprocessable Entity)**

```json
{
  "status": "error",
  "errors": ["Validation failed: invalid combination of section_type and part_type"]
}
```

---

## FastAPI実装例

### 依存ライブラリ

```python
pip install httpx pydantic
```

### 型定義

```python
from pydantic import BaseModel
from typing import Optional

class Question(BaseModel):
    display_order: int
    question_text: str
    question_audio_url: Optional[str] = None
    choice_a: str
    choice_b: str
    choice_c: str
    choice_d: str
    correct_choice: str  # "a" | "b" | "c" | "d"
    explanation: Optional[str] = None
    tag: Optional[str] = None
    wrong_reason_a: Optional[str] = None
    wrong_reason_b: Optional[str] = None
    wrong_reason_c: Optional[str] = None
    wrong_reason_d: Optional[str] = None

class QuestionSet(BaseModel):
    display_order: int
    passage: Optional[str] = None
    conversation_audio_url: Optional[str] = None
    questions: list[Question]
```

### クライアントクラス

```python
import httpx
import os

RAILS_API_BASE_URL = os.environ["RAILS_API_BASE_URL"]  # 例: http://localhost:3000
RAILS_API_KEY = os.environ["CONTENT_SOURCE_API_KEY"]

def get_headers() -> dict:
    return {
        "Authorization": f"Bearer {RAILS_API_KEY}",
        "Content-Type": "application/json",
    }

def post_mock(payload: dict) -> dict:
    """模擬試験を登録する"""
    with httpx.Client() as client:
        response = client.post(
            f"{RAILS_API_BASE_URL}/api/v1/mocks",
            json=payload,
            headers=get_headers(),
            timeout=30.0,
        )
        response.raise_for_status()
        return response.json()

def post_exercise(payload: dict) -> dict:
    """演習問題を登録する"""
    with httpx.Client() as client:
        response = client.post(
            f"{RAILS_API_BASE_URL}/api/v1/exercises",
            json=payload,
            headers=get_headers(),
            timeout=30.0,
        )
        response.raise_for_status()
        return response.json()
```

### 使用例（演習問題登録）

```python
payload = {
    "section_type": "listening",
    "part_type": "part_a",
    "question_sets": [
        {
            "display_order": 1,
            "conversation_audio_url": "https://example.com/audio/q1.mp3",
            "questions": [
                {
                    "display_order": 1,
                    "question_text": "What does the woman suggest?",
                    "choice_a": "She wants to leave.",
                    "choice_b": "She prefers to stay.",
                    "choice_c": "She is not sure.",
                    "choice_d": "She disagrees.",
                    "correct_choice": "b",
                    "explanation": "女性は滞在を希望していることがわかる。",
                    "tag": "提案",
                    "wrong_reason_a": "去りたいとは言っていない。",
                    "wrong_reason_c": "確信がないとは述べていない。",
                    "wrong_reason_d": "反対意見は述べていない。",
                }
            ],
        }
    ],
}

result = post_exercise(payload)
print(result)
# {"status": "success", "exercise_ids": [42], "created_count": 1}
```

---

## 環境変数

| 変数名 | 説明 |
|---|---|
| `RAILS_API_BASE_URL` | RailsサーバーのベースURL（例: `http://localhost:3000`） |
| `CONTENT_SOURCE_API_KEY` | API認証キー（Rails側と同じ値を設定） |

---

## エラーハンドリング指針

| HTTPステータス | 原因 | 対処 |
|---|---|---|
| 401 | APIキー不正・未設定 | 環境変数 `CONTENT_SOURCE_API_KEY` を確認 |
| 422 | バリデーションエラー | レスポンスの `errors` を確認し、ペイロードを修正 |
| 500 | サーバー側設定ミス | Rails側の `CONTENT_SOURCE_API_KEY` 環境変数を確認 |

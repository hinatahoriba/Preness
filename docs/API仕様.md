# API仕様

## 問題投入API

### 概要

- **データ投入元:** 外部の問題生成アプリケーション（FastAPI）からPOSTリクエストを受け取ります。
- **管理画面:** 不要（問題の確認・編集もAPIのみで行い、DBに直接反映されます）
- **認証方式:** 固定APIキー（環境変数 `CONTENT_API_KEY` で管理）
- **リクエストヘッダー:** `X-Api-Key: {CONTENT_API_KEY}`

### エンドポイント一覧

| エンドポイント | 用途 |
|---|---|
| `POST /api/v1/mocks` | 模擬試験の問題投入 |
| `POST /api/v1/exercises` | セクション別演習の問題投入 |

---

## POST /api/v1/mocks

模擬試験は3セクション（Listening / Structure / Reading）全てが必須。

### リクエストスキーマ

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
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "What does the woman imply?",
                  "audio_url": "https://preness-listening-audio.s3.ap-northeast-1.amazonaws.com/PartB_02.wav",
                  "choice_a": "The man should buy the book online.",
                  "choice_b": "The book might be held at a specific location.",
                  "choice_c": "The library is closed for research.",
                  "choice_d": "She has the book in her dorm room.",
                  "correct_choice": "B",
                  "explanation": "女性は本が“on reserve”かもしれないと言っており、特定の場所（フロントデスク）に保管されている可能性を示唆している。"
                }
              ]
            }
          ]
        },
        {
          "part_type": "part_b",
          "display_order": 2,
          "question_sets": [
            {
              "display_order": 1,
              "audio_url": "https://preness-listening-audio.s3.ap-northeast-1.amazonaws.com/PartB_02.wav",
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "What are the students mainly discussing?",
                  "choice_a": "Their plans for the upcoming weekend.",
                  "choice_b": "A research project for their biology class.",
                  "choice_c": "The requirements for a new scholarship.",
                  "choice_d": "How to organize a student study group.",
                  "correct_choice": "B",
                  "explanation": "会話の冒頭で生物学のプロジェクトについて話し合っているため。"
                }
              ]
            }
          ]
        },
        {
          "part_type": "part_c",
          "display_order": 3,
          "question_sets": [
            {
              "display_order": 1,
              "audio_url": "https://preness-listening-audio.s3.ap-northeast-1.amazonaws.com/PartB_02.wav",
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "What is the purpose of the talk?",
                  "choice_a": "To introduce new students to the campus library.",
                  "choice_b": "To explain the history of the university.",
                  "choice_c": "To discuss the benefits of a specific major.",
                  "choice_d": "To announce a change in the graduation requirements.",
                  "correct_choice": "A",
                  "explanation": "話し手は図書館の利用方法について説明しているため。"
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
      "parts": [
        {
          "part_type": "part_a",
          "display_order": 1,
          "question_sets": [
            {
              "display_order": 1,
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "The Eiffel Tower ------- in 1889 for the World's Fair.",
                  "choice_a": "was built",
                  "choice_b": "building",
                  "choice_c": "built",
                  "choice_d": "to build",
                  "correct_choice": "A",
                  "explanation": "受動態の形が必要。"
                }
              ]
            }
          ]
        },
        {
          "part_type": "part_b",
          "display_order": 2,
          "question_sets": [
            {
              "display_order": 1,
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "The (A) beautifully flowers (B) in the garden (C) are blooming (D) now.",
                  "choice_a": "A",
                  "choice_b": "B",
                  "choice_c": "C",
                  "choice_d": "D",
                  "correct_choice": "A",
                  "explanation": "副詞 beautifully ではなく、形容詞 beautiful が名詞 flowers を修飾すべき。"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "section_type": "reading",
      "display_order": 3,
      "parts": [
        {
          "part_type": "passages",
          "display_order": 1,
          "question_sets": [
            {
              "display_order": 1,
              "passage": "Modern computers are capable of performing billions of operations per second. This remarkable speed has revolutionized many fields, including science, engineering, and finance...",
              "questions": [
                {
                  "display_order": 1,
                  "question_text": "What is the main topic of the passage?",
                  "choice_a": "The history of vacuum tubes.",
                  "choice_b": "The speed and impact of modern computers.",
                  "choice_c": "How to repair a broken computer.",
                  "choice_d": "The cost of manufacturing microchips.",
                  "correct_choice": "B",
                  "explanation": "コンピュータの速度とその影響について述べられているため。"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### フィールド説明

| フィールド | 必須 | 説明 |
|---|---|---|
| `title` | ✅ | 模擬試験タイトル |
| `sections[].section_type` | ✅ | `listening` / `structure` / `reading` |
| `sections[].display_order` | ✅ | 表示順（1始まり） |
| `parts[].part_type` | ✅ | `part_a` / `part_b` / `part_c` / `passages` |
| `parts[].display_order` | ✅ | 表示順 |
| `question_sets[].passage` | 条件付き | readingのみ必須 |
| `question_sets[].audio_url` | 任意 | Part B / C のセット共通音声のS3 URL |
| `questions[].audio_url` | 任意 | 問題個別音声のS3 URL |
| `questions[].explanation` | 任意 | 解説文 |

### バリデーション

- `sections` に `listening` / `structure` / `reading` の3つが全て含まれること
- `correct_choice` は `A` / `B` / `C` / `D` のいずれか
- `audio_url` が指定された場合、そのままDBに保存する（Active Storageは使用しない）

### レスポンス（成功時）

```json
{
  "status": "success",
  "mock_id": 1,
  "title": "模擬試験 Vol.1"
}
```

### レスポンス（失敗時）

```json
{
  "status": "error",
  "errors": ["sections must include all three types: listening, structure, reading"]
}
```

---

## POST /api/v1/exercises

セクション別演習はパート単位で追加可能（3セクション揃っていなくても可）。

### リクエストスキーマ

```json
{
  "section_type": "listening",
  "part_type": "part_a",
  "question_sets": [
    {
      "display_order": 1,
      "questions": [
        {
          "display_order": 1,
          "question_text": "What does the woman suggest?",
          "audio_url": "https://s3.example.com/audio/practice_q1.mp3",
          "choice_a": "...",
          "choice_b": "...",
          "choice_c": "...",
          "choice_d": "...",
          "correct_choice": "A",
          "explanation": "..."
        }
      ]
    }
  ]
}
```

### フィールド説明

| フィールド | 必須 | 説明 |
|---|---|---|
| `section_type` | ✅ | `listening` / `structure` / `reading` |
| `part_type` | ✅ | `part_a` / `part_b` / `part_c` / `passages` |
| `question_sets` | ✅ | 1件以上 |
| `question_sets[].passage` | 条件付き | `reading` かつ `passages` の場合は必須 |
| `question_sets[].audio_url` | 任意 | Part B / C のセット共通音声 |
| `questions[].audio_url` | 任意 | 個別音声 |

### バリデーション

- `section_type` と `part_type` の組み合わせが有効であること（例: listeningにpassagesは不可）

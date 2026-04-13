# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

seed_sample_data = Rails.env.development? || ENV["SEED_SAMPLE_DATA"] == "1"

required_tables = %i[
  users
  exercises
  sections
  parts
  question_sets
  questions
  attempts
  answers
]

missing_tables = required_tables.reject do |table_name|
  ActiveRecord::Base.connection.data_source_exists?(table_name.to_s)
end

if missing_tables.any?
  puts "Skipping seeds: missing tables: #{missing_tables.join(', ')}"
  puts "Run: bin/rails db:migrate"
elsif !seed_sample_data
  puts "Skipping sample data seeds (set SEED_SAMPLE_DATA=1 to enable outside development)."
else
  SECTION_DISPLAY_ORDERS = {
    "listening" => 1,
    "structure" => 2,
    "reading" => 3
  }.freeze

  DEFAULT_SCRIPTS = [
    { speaker: "narrator", text: "Question 7." },
    { speaker: "man", text: "I'd like to check out these journals, but the self-checkout machine isn't taking my student ID." },
    { speaker: "woman", text: "It looks like you've got an outstanding fine on your account. You'll need to clear that up before borrowing anything." },
    { speaker: "narrator", text: "What does the woman imply?" }
  ].freeze

  PART_DISPLAY_ORDERS = {
    "part_a" => 1,
    "part_b" => 2,
    "part_c" => 3,
    "passages" => 1
  }.freeze

  def create_exercise_set!(section_type:, part_type:, set_number:, passage: nil, passage_thema: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
    exercise = Exercise.create!

    section = exercise.sections.create!(
      section_type: section_type,
      display_order: SECTION_DISPLAY_ORDERS.fetch(section_type)
    )

    part = section.parts.create!(
      part_type: part_type,
      display_order: PART_DISPLAY_ORDERS.fetch(part_type)
    )

    question_set = part.question_sets.create!(
      display_order: set_number,
      passage: passage,
      passage_thema: passage_thema,
      conversation_audio_url: audio_url,
      scripts: scripts
    )

    questions.each_with_index do |question_data, index|
      question_conversation_audio_url = if part_type == "part_a"
        question_data[:conversation_audio_url] || question_data[:question_audio_url] || audio_url
      end

      question_set.questions.create!(
        display_order: index + 1,
        question_text: question_data.fetch(:question_text),
        conversation_audio_url: question_conversation_audio_url,
        question_audio_url: question_data[:question_audio_url] || question_data[:audio_url],
        scripts: question_data[:scripts] || DEFAULT_SCRIPTS,
        choice_a: question_data.fetch(:choice_a),
        choice_b: question_data.fetch(:choice_b),
        choice_c: question_data.fetch(:choice_c),
        choice_d: question_data.fetch(:choice_d),
        correct_choice: question_data.fetch(:correct_choice),
        explanation: question_data[:explanation],
        tag: question_data[:tag],
        wrong_reason_a: question_data[:wrong_reason_a],
        wrong_reason_b: question_data[:wrong_reason_b],
        wrong_reason_c: question_data[:wrong_reason_c],
        wrong_reason_d: question_data[:wrong_reason_d]
      )
    end

    exercise
  end

  def create_mock_set!(mock:, section_type:, part_type:, set_number:, passage: nil, passage_thema: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
    section = mock.sections.find_or_create_by!(
      section_type: section_type,
      display_order: SECTION_DISPLAY_ORDERS.fetch(section_type)
    )

    part = section.parts.find_or_create_by!(
      part_type: part_type,
      display_order: PART_DISPLAY_ORDERS.fetch(part_type)
    )

    question_set = part.question_sets.create!(
      display_order: set_number,
      passage: passage,
      passage_thema: passage_thema,
      conversation_audio_url: audio_url,
      scripts: scripts
    )

    questions.each_with_index do |question_data, index|
      question_conversation_audio_url = if part_type == "part_a"
        question_data[:conversation_audio_url] || question_data[:question_audio_url] || audio_url
      end

      question_set.questions.create!(
        display_order: index + 1,
        question_text: question_data.fetch(:question_text),
        conversation_audio_url: question_conversation_audio_url,
        question_audio_url: question_data[:question_audio_url] || question_data[:audio_url],
        scripts: question_data[:scripts] || DEFAULT_SCRIPTS,
        choice_a: question_data.fetch(:choice_a),
        choice_b: question_data.fetch(:choice_b),
        choice_c: question_data.fetch(:choice_c),
        choice_d: question_data.fetch(:choice_d),
        correct_choice: question_data.fetch(:correct_choice),
        explanation: question_data[:explanation],
        tag: question_data[:tag],
        wrong_reason_a: question_data[:wrong_reason_a],
        wrong_reason_b: question_data[:wrong_reason_b],
        wrong_reason_c: question_data[:wrong_reason_c],
        wrong_reason_d: question_data[:wrong_reason_d]
      )
    end
  end

  puts "Seeding sample data..."

  ActiveRecord::Base.transaction do
    Answer.delete_all
    Attempt.delete_all
    Question.delete_all
    QuestionSet.delete_all
    Part.delete_all
    Section.delete_all
    Exercise.delete_all
    Mock.delete_all if ActiveRecord::Base.connection.data_source_exists?("mocks")
  end

  

  audio_url = "https://preness-listening-audio.s3.ap-northeast-1.amazonaws.com/PartB_02.wav"

  create_exercise_set!(
    section_type: "listening",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        tag: "shortConv",
        question_text: "What does the woman imply?",
        question_audio_url: audio_url,
        choice_a: "She will return the book today.",
        choice_b: "The book may be kept at the front desk.",
        choice_c: "The library is closed for research.",
        choice_d: "She has the book in her dorm room.",
        correct_choice: "B",
        explanation: "”on reserve” は特定の場所で保管されている可能性を示唆します。",
        wrong_reason_a: "本を返却するという発言は会話中にありません。女性は返すとは言っていない。",
        wrong_reason_c: "図書館が閉まっているという情報は会話に含まれておらず、文脈と合いません。",
        wrong_reason_d: "寮の部屋に本があるという手がかりは会話から読み取れません。"
      },
      {
        tag: "shortConv",
        question_text: "What will the man probably do next?",
        question_audio_url: audio_url,
        choice_a: "Ask at the front desk.",
        choice_b: "Go to the dormitory.",
        choice_c: "Buy the book online.",
        choice_d: "Cancel his research plan.",
        correct_choice: "A",
        explanation: "女性の示唆から、フロントデスクで確認するのが自然です。",
        wrong_reason_b: "寮に行くという流れは会話中に示されておらず、文脈に合いません。",
        wrong_reason_c: "オンラインで購入するという提案は会話に登場していません。",
        wrong_reason_d: "研究計画をキャンセルするという意図は会話から読み取れません。"
      },
      {
        tag: "shortConv",
        question_text: "Where does the conversation most likely take place?",
        question_audio_url: audio_url,
        choice_a: "At a café.",
        choice_b: "In a classroom.",
        choice_c: "At a library.",
        choice_d: "At a bookstore.",
        correct_choice: "C",
        explanation: "予約本やフロントデスクの話題から図書館が想定されます。",
        wrong_reason_a: "カフェという手がかりは会話の中に全くありません。",
        wrong_reason_b: "教室を示す言葉や状況描写が会話に含まれていません。",
        wrong_reason_d: "書店ではフロントデスクに本を「予約」する慣習はありません。"
      }
    ]
  )
  

  create_exercise_set!(
    section_type: "listening",
    part_type: "part_b",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "longConv",
        question_text: "What are the students mainly discussing?",
        question_audio_url: audio_url,
        choice_a: "Weekend plans.",
        choice_b: "A research project.",
        choice_c: "A scholarship requirement.",
        choice_d: "How to start a club.",
        correct_choice: "B",
        explanation: "会話の中心は授業のプロジェクトです。",
        wrong_reason_a: "週末の予定は会話の主題ではなく、付随的な話題に過ぎません。",
        wrong_reason_c: "奨学金の条件については会話中で触れられていません。",
        wrong_reason_d: "クラブの立ち上げ方は会話のテーマとは無関係です。"
      },
      {
        tag: "longConv",
        question_text: "What does the woman offer to do?",
        question_audio_url: audio_url,
        choice_a: "Collect the data.",
        choice_b: "Write the introduction.",
        choice_c: "Make the slides.",
        choice_d: "Present alone.",
        correct_choice: "C",
        explanation: "発表用のスライド作成を引き受けています。",
        wrong_reason_a: "データ収集は女性が担当するとは述べられていません。",
        wrong_reason_b: "序論の執筆を女性が引き受けるという内容は会話にありません。",
        wrong_reason_d: "一人で発表するという提案は会話中に出てきません。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "listening",
    part_type: "part_c",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "talk",
        question_text: "What is the purpose of the talk?",
        question_audio_url: audio_url,
        choice_a: "To introduce the library services.",
        choice_b: "To explain campus history.",
        choice_c: "To describe a new major.",
        choice_d: "To announce new graduation rules.",
        correct_choice: "A",
        explanation: "図書館の使い方を案内しています。",
        wrong_reason_b: "キャンパスの歴史の説明はトークの内容に含まれていません。",
        wrong_reason_c: "新専攻の説明はトークのテーマではありません。",
        wrong_reason_d: "卒業要件の発表はトーク中に出てきません。"
      },
      {
        tag: "talk",
        question_text: "What does the speaker recommend?",
        question_audio_url: audio_url,
        choice_a: "Borrowing only one book at a time.",
        choice_b: "Using the online catalog.",
        choice_c: "Avoiding group study rooms.",
        choice_d: "Buying textbooks immediately.",
        correct_choice: "B",
        explanation: "オンラインカタログの利用が推奨されています。",
        wrong_reason_a: "一度に1冊だけ借りるよう勧める発言はトーク中にありません。",
        wrong_reason_c: "グループ学習室を避けるようにとは述べられていません。",
        wrong_reason_d: "教科書をすぐ購入するよう勧める内容はトークに含まれていません。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "structure",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        tag: "verbForm",
        question_text: "The Eiffel Tower ______ in 1889 for the World's Fair.",
        choice_a: "was built",
        choice_b: "building",
        choice_c: "built",
        choice_d: "to build",
        correct_choice: "A",
        explanation: "受動態が必要です。",
        wrong_reason_b: "building は現在分詞・動名詞で、主語の動詞として使えません。",
        wrong_reason_c: "built は能動態の過去形で、主語が「建てた」側になり意味が不自然です。",
        wrong_reason_d: "to build は不定詞で、文の述語動詞にはなれません。"
      },
      {
        tag: "verbForm",
        question_text: "If I ______ more time, I would travel more often.",
        choice_a: "have",
        choice_b: "had",
        choice_c: "will have",
        choice_d: "am having",
        correct_choice: "B",
        explanation: "仮定法過去の形です。",
        wrong_reason_a: "have は直説法現在形で、仮定法過去の文には使えません。",
        wrong_reason_c: "will have は未来形で、仮定法の if 節では使いません。",
        wrong_reason_d: "am having は現在進行形で、仮定法の if 節に合いません。"
      },
      {
        tag: "verbForm",
        question_text: "The report must ______ by Friday.",
        choice_a: "submit",
        choice_b: "submitted",
        choice_c: "be submitted",
        choice_d: "submitting",
        correct_choice: "C",
        explanation: "must + be + 過去分詞。",
        wrong_reason_a: "must submit は能動態で「誰かが提出しなければならない」という意味になり不自然です。",
        wrong_reason_b: "must submitted は文法的に誤りです。助動詞の後には原形が必要です。",
        wrong_reason_d: "must submitting は文法的に誤りです。助動詞の後に -ing 形は使えません。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "structure",
    part_type: "part_b",
    set_number: 1,
    questions: [
      {
        tag: "modifierConnect",
        question_text: "The [A]beautifully[/A] flowers [B]in the garden[/B] [C]are blooming[/C] [D]now[/D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "beautifully → beautiful が適切です。",
        wrong_reason_b: "in the garden は場所を示す前置詞句として正しく使われています。",
        wrong_reason_c: "are blooming は主語 flowers（複数）に対応した正しい進行形です。",
        wrong_reason_d: "now は時を表す副詞として文法的に問題ありません。"
      },
      {
        tag: "verbForm",
        question_text: "She [A]suggested me[/A] [B]to take[/B] [C]a short break[/C] [D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "B",
        explanation: "suggested me → suggested that I / suggested taking の形。",
        wrong_reason_a: "She は主語として文法的に正しく使われています。",
        wrong_reason_c: "a short break は名詞句として文法的に問題ありません。",
        wrong_reason_d: "文末に余分な語はなく、D の箇所は誤りではありません。"
      },
      {
        tag: "modifierConnect",
        question_text: "I [A]have lived[/A] [B]here[/B] [C]since[/C] [D]five years[/D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "D",
        explanation: "since five years → for five years。",
        wrong_reason_a: "have lived は現在完了形として文法的に正しい形です。",
        wrong_reason_b: "here は場所を示す副詞として正しく使われています。",
        wrong_reason_c: "C の箇所（five years の直前）は誤りの箇所ではありません。誤りは since という語そのものです。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "reading",
    part_type: "passages",
    set_number: 1,
    passage_thema: "Modern Computers",
    passage: <<~TEXT,
      Modern computers are capable of performing billions of operations per second.
      This remarkable speed has revolutionized many fields, including science, engineering, and finance.
    TEXT
    questions: [
      {
        tag: "inference",
        question_text: "What is the main topic of the passage?",
        choice_a: "The history of vacuum tubes.",
        choice_b: "The speed and impact of modern computers.",
        choice_c: "How to repair a broken computer.",
        choice_d: "The cost of manufacturing microchips.",
        correct_choice: "B",
        explanation: "コンピュータの高速化と影響について述べています。",
        wrong_reason_a: "真空管の歴史については本文中に全く言及されていません。",
        wrong_reason_c: "コンピュータの修理方法は本文のテーマではありません。",
        wrong_reason_d: "マイクロチップの製造コストは本文中で触れられていません。"
      },
      {
        tag: "fact",
        question_text: "Which fields are mentioned as being affected?",
        choice_a: "Science, engineering, finance.",
        choice_b: "Art, music, sports.",
        choice_c: "Cooking, farming, fishing.",
        choice_d: "Travel, fashion, design.",
        correct_choice: "A",
        explanation: "本文に明記されています。",
        wrong_reason_b: "芸術・音楽・スポーツは本文中に言及されていません。",
        wrong_reason_c: "料理・農業・漁業は本文の話題に含まれていません。",
        wrong_reason_d: "旅行・ファッション・デザインは本文に登場しません。"
      },
      {
        tag: "vocab",
        question_text: "What does 'remarkable' most nearly mean?",
        choice_a: "Ordinary",
        choice_b: "Notable",
        choice_c: "Unsafe",
        choice_d: "Slow",
        correct_choice: "B",
        explanation: "remarkable は「注目すべき」の意味です。",
        wrong_reason_a: "ordinary は「普通の・平凡な」という意味で、remarkable の反意語に近いです。",
        wrong_reason_c: "unsafe は「危険な」という意味で、remarkable とは全く関係がありません。",
        wrong_reason_d: "slow は「遅い」という意味で、文脈上「速さ」を称賛する語と反対の意味です。"
      }
    ]
  )

  

  puts "Seeding mock exam data..."
  mock1 = Mock.create!(title: "第1回 模擬試験")

  create_mock_set!(
    mock: mock1,
    section_type: "listening",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        tag: "shortConv",
        question_text: "What does the woman imply?",
        question_audio_url: audio_url,
        choice_a: "She will return the book today.",
        choice_b: "The book may be kept at the front desk.",
        choice_c: "The library is closed for research.",
        choice_d: "She has the book in her dorm room.",
        correct_choice: "B",
        explanation: '"on reserve" は特定の場所で保管されている可能性を示唆します。',
        wrong_reason_a: "本を返却するという発言は会話中にありません。女性は返すとは言っていない。",
        wrong_reason_c: "図書館が閉まっているという情報は会話に含まれておらず、文脈と合いません。",
        wrong_reason_d: "寮の部屋に本があるという手がかりは会話から読み取れません。"
      },
      {
        tag: "shortConv",
        question_text: "What will the man probably do next?",
        question_audio_url: audio_url,
        choice_a: "Ask at the front desk.",
        choice_b: "Go to the dormitory.",
        choice_c: "Buy the book online.",
        choice_d: "Cancel his research plan.",
        correct_choice: "A",
        explanation: "女性の示唆から、フロントデスクで確認するのが自然です。",
        wrong_reason_b: "寮に行くという流れは会話中に示されておらず、文脈に合いません。",
        wrong_reason_c: "オンラインで購入するという提案は会話に登場していません。",
        wrong_reason_d: "研究計画をキャンセルするという意図は会話から読み取れません。"
      },
      {
        tag: "shortConv",
        question_text: "Where does the conversation most likely take place?",
        question_audio_url: audio_url,
        choice_a: "At a café.",
        choice_b: "In a classroom.",
        choice_c: "At a library.",
        choice_d: "At a bookstore.",
        correct_choice: "C",
        explanation: "予約本やフロントデスクの話題から図書館が想定されます。",
        wrong_reason_a: "カフェという手がかりは会話の中に全くありません。",
        wrong_reason_b: "教室を示す言葉や状況描写が会話に含まれていません。",
        wrong_reason_d: "書店ではフロントデスクに本を「予約」する慣習はありません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "listening",
    part_type: "part_b",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "longConv",
        question_text: "What are the students mainly discussing?",
        question_audio_url: audio_url,
        choice_a: "Weekend plans.",
        choice_b: "A research project.",
        choice_c: "A scholarship requirement.",
        choice_d: "How to start a club.",
        correct_choice: "B",
        explanation: "会話の中心は授業のプロジェクトです。",
        wrong_reason_a: "週末の予定は会話の主題ではなく、付随的な話題に過ぎません。",
        wrong_reason_c: "奨学金の条件については会話中で触れられていません。",
        wrong_reason_d: "クラブの立ち上げ方は会話のテーマとは無関係です。"
      },
      {
        tag: "longConv",
        question_text: "What does the woman offer to do?",
        question_audio_url: audio_url,
        choice_a: "Collect the data.",
        choice_b: "Write the introduction.",
        choice_c: "Make the slides.",
        choice_d: "Present alone.",
        correct_choice: "C",
        explanation: "発表用のスライド作成を引き受けています。",
        wrong_reason_a: "データ収集は女性が担当するとは述べられていません。",
        wrong_reason_b: "序論の執筆を女性が引き受けるという内容は会話にありません。",
        wrong_reason_d: "一人で発表するという提案は会話中に出てきません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "listening",
    part_type: "part_c",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "talk",
        question_text: "What is the purpose of the talk?",
        question_audio_url: audio_url,
        choice_a: "To introduce the library services.",
        choice_b: "To explain campus history.",
        choice_c: "To describe a new major.",
        choice_d: "To announce new graduation rules.",
        correct_choice: "A",
        explanation: "図書館の使い方を案内しています。",
        wrong_reason_b: "キャンパスの歴史の説明はトークの内容に含まれていません。",
        wrong_reason_c: "新専攻の説明はトークのテーマではありません。",
        wrong_reason_d: "卒業要件の発表はトーク中に出てきません。"
      },
      {
        tag: "talk",
        question_text: "What does the speaker recommend?",
        question_audio_url: audio_url,
        choice_a: "Borrowing only one book at a time.",
        choice_b: "Using the online catalog.",
        choice_c: "Avoiding group study rooms.",
        choice_d: "Buying textbooks immediately.",
        correct_choice: "B",
        explanation: "オンラインカタログの利用が推奨されています。",
        wrong_reason_a: "一度に1冊だけ借りるよう勧める発言はトーク中にありません。",
        wrong_reason_c: "グループ学習室を避けるようにとは述べられていません。",
        wrong_reason_d: "教科書をすぐ購入するよう勧める内容はトークに含まれていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "structure",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        tag: "verbForm",
        question_text: "The Eiffel Tower _______ in 1889 for the World's Fair.",
        choice_a: "was built",
        choice_b: "building",
        choice_c: "built",
        choice_d: "to build",
        correct_choice: "A",
        explanation: "受動態が必要です。",
        wrong_reason_b: "building は現在分詞・動名詞で、主語の動詞として使えません。",
        wrong_reason_c: "built は能動態の過去形で、主語が「建てた」側になり意味が不自然です。",
        wrong_reason_d: "to build は不定詞で、文の述語動詞にはなれません。"
      },
      {
        tag: "verbForm",
        question_text: "If I _______ more time, I would travel more often.",
        choice_a: "have",
        choice_b: "had",
        choice_c: "will have",
        choice_d: "am having",
        correct_choice: "B",
        explanation: "仮定法過去の形です。",
        wrong_reason_a: "have は直説法現在形で、仮定法過去の文には使えません。",
        wrong_reason_c: "will have は未来形で、仮定法の if 節では使いません。",
        wrong_reason_d: "am having は現在進行形で、仮定法の if 節に合いません。"
      },
      {
        tag: "verbForm",
        question_text: "The report must _______ by Friday.",
        choice_a: "submit",
        choice_b: "submitted",
        choice_c: "be submitted",
        choice_d: "submitting",
        correct_choice: "C",
        explanation: "must + be + 過去分詞。",
        wrong_reason_a: "must submit は能動態で「誰かが提出しなければならない」という意味になり不自然です。",
        wrong_reason_b: "must submitted は文法的に誤りです。助動詞の後には原形が必要です。",
        wrong_reason_d: "must submitting は文法的に誤りです。助動詞の後に -ing 形は使えません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "reading",
    part_type: "passages",
    set_number: 1,
    passage_thema: "Modern Computers",
    passage: <<~TEXT,
      Modern computers are capable of performing billions of operations per second, a feat that would have seemed impossible just a few decades ago. This remarkable speed has revolutionized many fields, including science, engineering, and finance. In scientific research, computers allow scientists to model complex systems such as climate patterns, protein structures, and the behavior of subatomic particles. Engineers use computing power to simulate designs and test them virtually before physical prototypes are ever built, reducing both cost and time. In finance, high-speed computers execute trades in fractions of a second, analyze market trends, and manage risk across enormous datasets.

      The foundation of this computing power lies in the microprocessor, a tiny chip that can contain billions of transistors. Over the decades, the number of transistors that can fit on a chip has roughly doubled every two years — a trend famously described as Moore's Law. While this rate of growth has begun to slow due to physical limitations at the atomic scale, new approaches such as parallel processing, quantum computing, and neuromorphic chips are being explored to continue expanding computational capacity.

      Despite these advances, computers still face significant limitations. They excel at tasks defined by clear rules and large datasets, but struggle with tasks requiring common sense, emotional understanding, or creativity. Researchers in artificial intelligence are actively working to address these gaps, but many experts believe that truly general machine intelligence remains a long-term challenge.
    TEXT
    questions: [
      {
        tag: "inference",
        question_text: "What is the main topic of the passage?",
        choice_a: "The history of vacuum tubes.",
        choice_b: "The speed and impact of modern computers.",
        choice_c: "How to repair a broken computer.",
        choice_d: "The cost of manufacturing microchips.",
        correct_choice: "B",
        explanation: "コンピュータの高速化と影響について述べています。",
        wrong_reason_a: "真空管の歴史については本文中に全く言及されていません。",
        wrong_reason_c: "コンピュータの修理方法は本文のテーマではありません。",
        wrong_reason_d: "マイクロチップの製造コストは本文中で触れられていません。"
      },
      {
        tag: "fact",
        question_text: "Which fields are mentioned as being affected?",
        choice_a: "Science, engineering, finance.",
        choice_b: "Art, music, sports.",
        choice_c: "Cooking, farming, fishing.",
        choice_d: "Travel, fashion, design.",
        correct_choice: "A",
        explanation: "本文に明記されています。",
        wrong_reason_b: "芸術・音楽・スポーツは本文中に言及されていません。",
        wrong_reason_c: "料理・農業・漁業は本文の話題に含まれていません。",
        wrong_reason_d: "旅行・ファッション・デザインは本文に登場しません。"
      },
      {
        tag: "vocab",
        question_text: "What does 'remarkable' most nearly mean?",
        choice_a: "Ordinary",
        choice_b: "Notable",
        choice_c: "Unsafe",
        choice_d: "Slow",
        correct_choice: "B",
        explanation: "remarkable は「注目すべき」の意味です。",
        wrong_reason_a: "ordinary は「普通の・平凡な」という意味で、remarkable の反意語に近いです。",
        wrong_reason_c: "unsafe は「危険な」という意味で、remarkable とは全く関係がありません。",
        wrong_reason_d: "slow は「遅い」という意味で、文脈上「速さ」を称賛する語と反対の意味です。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "structure",
    part_type: "part_b",
    set_number: 1,
    questions: [
      {
        tag: "sentenceStruct",
        question_text: "Neither the manager nor the employees [A]was[/A] [B]informed[/B] about [C]the[/C] [D]policy change[/D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "Neither A nor B の場合、動詞は B（employees）に一致するため were が正しいです。",
        wrong_reason_b: "informed は受動態の過去分詞として正しく使われています。",
        wrong_reason_c: "the は定冠詞として正しく機能しています。",
        wrong_reason_d: "policy change という名詞句は文法的に問題ありません。"
      },
      {
        tag: "modifierConnect",
        question_text: "[A]Despite of[/A] [B]the heavy rain[/B], the outdoor concert [C]continued[/C] [D]as planned[/D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "despite は前置詞で of は不要です。despite the heavy rain が正しい形です。",
        wrong_reason_b: "the heavy rain は despite の目的語として正しく機能しています。",
        wrong_reason_c: "continued は過去形の動詞として文法的に正しいです。",
        wrong_reason_d: "as planned は「予定通り」を意味する句として正しく使われています。"
      },
      {
        tag: "nounPronoun",
        question_text: "The committee [A]which[/A] [B]was formed[/B] last year [C]has made[/C] [D]their[/D] final decision.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "D",
        explanation: "committee は単数の集合名詞なので、代名詞は their ではなく its が正しいです。",
        wrong_reason_a: "which は先行詞 committee（組織）を受ける正しい関係代名詞です。",
        wrong_reason_b: "was formed は受動態として正しく使われています。",
        wrong_reason_c: "has made は現在完了形として正しいです。"
      },
      {
        tag: "verbForm",
        question_text: "The data [A]collected[/A] during the study [B]suggests[/B] that the treatment [C]is[/C] [D]highly effective[/D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "B",
        explanation: "data は複数形なので suggest が正しいです。",
        wrong_reason_a: "collected は過去分詞として data を修飾する正しい用法です。",
        wrong_reason_c: "is は that 節内の述語動詞として正しく機能しています。",
        wrong_reason_d: "highly effective は形容詞句として正しいです。"
      },
      {
        tag: "sentenceStruct",
        question_text: "Not only [A]she studied[/A] hard, [B]but[/B] she also [C]volunteered[/C] at the [D]local shelter[/D].",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "Not only が文頭に来る場合、倒置が必要です。Not only did she study が正しい形です。",
        wrong_reason_b: "but は not only...but also の相関接続詞として正しく使われています。",
        wrong_reason_c: "volunteered は過去形の動詞として正しいです。",
        wrong_reason_d: "local shelter は名詞句として正しいです。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "reading",
    part_type: "passages",
    set_number: 2,
    passage_thema: "The Water Cycle",
    passage: <<~TEXT,
      The water cycle, also known as the hydrological cycle, describes the continuous movement of water through Earth's systems. Water evaporates from oceans, lakes, and rivers when heat from the sun causes liquid water to transform into water vapor. This vapor rises into the atmosphere, cools, and condenses to form clouds through a process called condensation. Eventually, the water returns to Earth's surface as precipitation in the form of rain, snow, sleet, or hail.

      Once precipitation reaches the ground, it follows several different paths. Some water flows over the surface as runoff, feeding streams and rivers that eventually return water to the ocean. Other water seeps into the soil and becomes groundwater, which can be stored in underground reservoirs called aquifers for thousands of years. Plants also play a role by absorbing groundwater through their roots and releasing it back into the atmosphere through transpiration, a process that contributes significantly to the water cycle in forested regions.

      Human activities have increasingly disrupted the natural water cycle. Deforestation reduces transpiration and alters local rainfall patterns. Urbanization replaces permeable soil with concrete and asphalt, increasing runoff and reducing groundwater recharge. Climate change is intensifying the water cycle, making droughts more severe in some regions while causing heavier rainfall and flooding in others. Understanding the water cycle is essential for managing water resources sustainably and responding to the challenges posed by a changing climate.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "What happens to water vapor as it rises into the atmosphere?",
        choice_a: "It evaporates again.",
        choice_b: "It turns into groundwater.",
        choice_c: "It cools and condenses to form clouds.",
        choice_d: "It is absorbed by plants.",
        correct_choice: "C",
        explanation: "本文に「cools, and condenses to form clouds」と明記されています。",
        wrong_reason_a: "水蒸気は大気中で再び蒸発するとは書かれていません。",
        wrong_reason_b: "地下水になるのは降水後の地面への浸透であり、水蒸気が直接地下水になるとは書かれていません。",
        wrong_reason_d: "植物が水蒸気を吸収するという記述は本文にありません。"
      },
      {
        tag: "fact",
        question_text: "What is an aquifer?",
        choice_a: "A type of cloud formation.",
        choice_b: "An underground reservoir of groundwater.",
        choice_c: "A surface river fed by runoff.",
        choice_d: "A measurement of rainfall.",
        correct_choice: "B",
        explanation: "「underground reservoirs called aquifers」と本文に定義されています。",
        wrong_reason_a: "雲の形成とアクアファーは無関係です。",
        wrong_reason_c: "地表の川は runoff が流れ込むもので、aquifer とは異なります。",
        wrong_reason_d: "降雨量の測定単位はアクアファーとは関係ありません。"
      },
      {
        tag: "inference",
        question_text: "What can be inferred about deforestation's effect on the water cycle?",
        choice_a: "It increases transpiration.",
        choice_b: "It has no effect on rainfall.",
        choice_c: "It reduces the return of water to the atmosphere.",
        choice_d: "It improves groundwater recharge.",
        correct_choice: "C",
        explanation: "森林破壊は蒸散を減少させ、大気への水の還元を減らすと推測できます。",
        wrong_reason_a: "森林破壊は蒸散を増加ではなく減少させます。",
        wrong_reason_b: "本文では森林破壊が地域の降雨パターンを変えると述べています。",
        wrong_reason_d: "都市化が地下水涵養を減少させると述べられており、森林破壊が改善するとは書かれていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "reading",
    part_type: "passages",
    set_number: 3,
    passage_thema: "The Industrial Revolution",
    passage: <<~TEXT,
      The Industrial Revolution, which began in Britain in the mid-18th century, fundamentally transformed how goods were produced and how people lived and worked. Before this period, most manufacturing took place in homes or small workshops using hand tools and human or animal power. The invention of steam-powered machinery allowed factories to produce goods on a scale previously unimaginable, dramatically increasing the output of textiles, iron, and coal.

      The revolution spread from Britain to Europe and North America over the following century, reshaping economies and societies along the way. Urbanization accelerated as workers left rural areas to find employment in factories, leading to the rapid growth of industrial cities. These cities often struggled to accommodate the influx of workers, resulting in overcrowded housing, poor sanitation, and long working hours under dangerous conditions. Child labor was widespread, with many factories employing young children for tasks that adults could not easily perform.

      Despite its social costs, the Industrial Revolution laid the foundation for modern economic systems. It drove technological innovation, expanded global trade networks, and raised living standards over the long term. The legal and social reforms that followed — including labor laws, public health regulations, and universal education — were in many ways a direct response to the challenges created by rapid industrialization.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "Where did the Industrial Revolution begin?",
        choice_a: "France.",
        choice_b: "The United States.",
        choice_c: "Germany.",
        choice_d: "Britain.",
        correct_choice: "D",
        explanation: "本文冒頭に「began in Britain」と明記されています。",
        wrong_reason_a: "フランスには後に広まりましたが、始まりの地ではありません。",
        wrong_reason_b: "アメリカには19世紀に広まりましたが、発祥の地ではありません。",
        wrong_reason_c: "ドイツはその後工業化しましたが、産業革命の発祥地ではありません。"
      },
      {
        tag: "fact",
        question_text: "What caused rapid urban growth during the Industrial Revolution?",
        choice_a: "Government relocation programs.",
        choice_b: "Workers moving from rural areas to factories.",
        choice_c: "The decline of international trade.",
        choice_d: "Agricultural improvements increasing food supply.",
        correct_choice: "B",
        explanation: "農村部から工場での雇用を求めた労働者の移動が都市化を加速させました。",
        wrong_reason_a: "政府による移住プログラムは本文に記載されていません。",
        wrong_reason_c: "国際貿易の衰退は本文と逆の内容です。実際には拡大しました。",
        wrong_reason_d: "農業改善は本文の都市化の説明に含まれていません。"
      },
      {
        tag: "vocab",
        question_text: "What does 'influx' most nearly mean?",
        choice_a: "Departure.",
        choice_b: "A large arrival.",
        choice_c: "A gradual decline.",
        choice_d: "A financial investment.",
        correct_choice: "B",
        explanation: "influx は「大量の流入」を意味します。",
        wrong_reason_a: "departure は「出発・退去」でinfluxの反対に近いです。",
        wrong_reason_c: "gradual decline（緩やかな減少）はinfluxの意味と正反対です。",
        wrong_reason_d: "financial investment（財務投資）は文脈と無関係です。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "reading",
    part_type: "passages",
    set_number: 4,
    passage_thema: "Biodiversity and Ecosystems",
    passage: <<~TEXT,
      Biodiversity refers to the variety of life on Earth, encompassing the diversity of species, genes, and ecosystems. It is a measure of the health and complexity of natural systems and is essential for the functioning of ecosystems. Each species within an ecosystem plays a specific role — whether as a producer, consumer, or decomposer — and the loss of any one species can trigger cascading effects throughout the food web.

      Ecosystems provide a wide range of services that human societies depend on, often called ecosystem services. These include the purification of air and water, pollination of crops, decomposition of waste, regulation of climate, and the provision of food and raw materials. Forests, wetlands, coral reefs, and grasslands are among the most productive ecosystems in terms of the services they provide, yet they are also among the most threatened by human activity.

      The current rate of species extinction is estimated to be between 1,000 and 10,000 times higher than natural background rates, largely due to habitat destruction, pollution, invasive species, excessive hunting, and climate change. This rapid loss of biodiversity threatens not only wildlife but also the long-term resilience of human civilization. Conservation efforts, including protected areas, habitat restoration, and international agreements, are critical for reversing these trends.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "What is biodiversity?",
        choice_a: "The study of ecosystems.",
        choice_b: "The variety of species, genes, and ecosystems on Earth.",
        choice_c: "The number of plants in a given area.",
        choice_d: "A type of environmental policy.",
        correct_choice: "B",
        explanation: "本文冒頭に「variety of life on Earth, encompassing the diversity of species, genes, and ecosystems」と定義されています。",
        wrong_reason_a: "生態系の研究は生態学であり、生物多様性の定義ではありません。",
        wrong_reason_c: "植物の数だけを指すものではなく、全ての生命の多様性を指します。",
        wrong_reason_d: "環境政策の一種とは本文に書かれていません。"
      },
      {
        tag: "inference",
        question_text: "What can be inferred about the loss of a single species?",
        choice_a: "It rarely affects other species.",
        choice_b: "It can have widespread effects throughout an ecosystem.",
        choice_c: "It only impacts producers in the food web.",
        choice_d: "It always leads to ecosystem collapse.",
        correct_choice: "B",
        explanation: "本文に「cascading effects throughout the food web」と述べられており、広範な影響が推測されます。",
        wrong_reason_a: "本文の「cascading effects」の記述から、1種の消失が他に影響しないとは言えません。",
        wrong_reason_c: "生産者だけでなく、消費者・分解者全てに影響が及ぶ可能性があります。",
        wrong_reason_d: "必ずしも完全な崩壊につながるとは本文に書かれていません。"
      },
      {
        tag: "fact",
        question_text: "What is one major cause of species extinction mentioned in the passage?",
        choice_a: "Volcanic eruptions.",
        choice_b: "Natural predation.",
        choice_c: "Habitat destruction.",
        choice_d: "Solar activity.",
        correct_choice: "C",
        explanation: "本文に「habitat destruction」が主要原因のひとつとして明記されています。",
        wrong_reason_a: "火山噴火は本文中に原因として挙げられていません。",
        wrong_reason_b: "自然の捕食は生態系の正常な機能であり、絶滅の主要原因として本文では挙げられていません。",
        wrong_reason_d: "太陽活動は本文に記載されていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock1,
    section_type: "reading",
    part_type: "passages",
    set_number: 5,
    passage_thema: "Artificial Intelligence",
    passage: <<~TEXT,
      Artificial intelligence, commonly abbreviated as AI, refers to the simulation of human intelligence processes by computer systems. These processes include learning, reasoning, problem-solving, perception, and language understanding. While the concept of thinking machines has existed for centuries in folklore and philosophy, modern AI emerged as a formal field of study in the mid-20th century, fueled by advances in computing power and the development of foundational algorithms.

      Today, AI encompasses a broad range of technologies, from rule-based expert systems to machine learning models that can identify patterns in enormous datasets. Deep learning, a subset of machine learning, uses artificial neural networks modeled loosely on the human brain to achieve breakthroughs in image recognition, natural language processing, and game playing. Systems such as large language models can generate fluent text, translate languages, and answer questions with remarkable accuracy, though they still lack genuine understanding or consciousness.

      The rapid advancement of AI raises important ethical and social questions. Concerns about job displacement, algorithmic bias, privacy, and the concentration of power among a small number of technology companies are widely debated. Governments and international organizations are working to develop regulatory frameworks to govern the development and deployment of AI responsibly. Despite these challenges, AI has the potential to accelerate scientific discovery, improve healthcare outcomes, and address complex global problems.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "When did modern AI emerge as a formal field of study?",
        choice_a: "In the early 19th century.",
        choice_b: "In the mid-20th century.",
        choice_c: "In the late 18th century.",
        choice_d: "At the beginning of the 21st century.",
        correct_choice: "B",
        explanation: "本文に「mid-20th century」と明記されています。",
        wrong_reason_a: "19世紀初頭は現代AIの誕生より100年以上前であり、本文の記述と異なります。",
        wrong_reason_c: "18世紀後半はAI研究が存在しなかった時代で、本文とは異なります。",
        wrong_reason_d: "21世紀初頭ではなく、20世紀中頃と本文に書かれています。"
      },
      {
        tag: "vocab",
        question_text: "What does 'simulate' most nearly mean?",
        choice_a: "To destroy.",
        choice_b: "To imitate or replicate.",
        choice_c: "To measure accurately.",
        choice_d: "To suppress.",
        correct_choice: "B",
        explanation: "simulate は「模倣する・再現する」という意味です。",
        wrong_reason_a: "destroy（破壊する）はsimulateとは全く逆の意味です。",
        wrong_reason_c: "measure accurately（正確に測定する）はsimulateの意味とは異なります。",
        wrong_reason_d: "suppress（抑制する）はsimulateの意味とは無関係です。"
      },
      {
        tag: "inference",
        question_text: "What does the passage suggest about large language models?",
        choice_a: "They fully understand language.",
        choice_b: "They are conscious like humans.",
        choice_c: "They can produce fluent text but lack true understanding.",
        choice_d: "They are no longer being developed.",
        correct_choice: "C",
        explanation: "「generate fluent text...though they still lack genuine understanding or consciousness」と本文に述べられています。",
        wrong_reason_a: "「lack genuine understanding」とあるため、完全な言語理解はないとされています。",
        wrong_reason_b: "「lack...consciousness」とあり、意識があるとは述べられていません。",
        wrong_reason_d: "開発が止まっているという記述は本文にありません。"
      }
    ]
  )

  # Create test user
  test_user = User.find_or_create_by!(email: "testuser@gmail.com") do |user|
    user.password = "testuser"
    user.password_confirmation = "testuser"
    user.terms_agreed = true
    user.confirmed_at = Time.current
  end

  # Create initial settings for test user
  test_user_profile = test_user.user_profile || test_user.build_user_profile
  test_user_profile.update!(
    last_name: "Test",
    first_name: "User",
    last_name_kana: "テスト",
    first_name_kana: "ユーザー",
    nickname: "testuser",
    date_of_birth: Date.new(2000, 1, 1),
    affiliation: "Test Company",
    study_abroad_plan: false,
    itp_target_score: 500
  )

  puts "Test user created: testuser@gmail.com"
  puts "Seed finished."
end

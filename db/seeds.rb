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

  def create_exercise_set!(section_type:, part_type:, set_number:, passage: nil, passage_theme: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
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
      passage_theme: passage_theme,
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

  def create_diagnostic_set!(diagnostic:, section_type:, part_type:, set_number:, passage: nil, passage_theme: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
    section = diagnostic.sections.find_or_create_by!(
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
      passage_theme: passage_theme,
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

  def create_mock_set!(mock:, section_type:, part_type:, set_number:, passage: nil, passage_theme: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
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
      passage_theme: passage_theme,
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
    Diagnostic.delete_all if ActiveRecord::Base.connection.data_source_exists?("diagnostics")
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
    passage_theme: "Modern Computers",
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
    passage_theme: "Modern Computers",
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
    passage_theme: "The Water Cycle",
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
    passage_theme: "The Industrial Revolution",
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
    passage_theme: "Biodiversity and Ecosystems",
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
    passage_theme: "Artificial Intelligence",
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

  # ─── Diagnostic seed data ────────────────────────────────────────────────────
  puts "Seeding diagnostic data..."
  diagnostic1 = Diagnostic.create!(title: "実力診断テスト Vol.1")

  # Listening Part A (shortConv) – 8 questions
  create_diagnostic_set!(
    diagnostic: diagnostic1,
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
        choice_c: "The library is closed.",
        choice_d: "She has the book at home.",
        correct_choice: "B",
        explanation: '"on reserve" はフロントデスクで保管されている可能性を示唆します。',
        wrong_reason_a: "本を返すとは述べられていません。",
        wrong_reason_c: "図書館が閉まっているという情報は会話にありません。",
        wrong_reason_d: "寮に本があるという手がかりはありません。"
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
        explanation: "女性の示唆からフロントデスクで確認するのが自然な流れです。",
        wrong_reason_b: "寮に行く流れは会話から読み取れません。",
        wrong_reason_c: "オンライン購入は会話に登場していません。",
        wrong_reason_d: "研究計画キャンセルの意図はありません。"
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
        explanation: "予約本とフロントデスクの話題から図書館が想定されます。",
        wrong_reason_a: "カフェという手がかりは全くありません。",
        wrong_reason_b: "教室を示す描写がありません。",
        wrong_reason_d: "書店でフロントデスクに本を予約する慣習はありません。"
      },
      {
        tag: "shortConv",
        question_text: "What does the man mean?",
        question_audio_url: audio_url,
        choice_a: "He forgot his assignment.",
        choice_b: "He needs more time to finish.",
        choice_c: "He already submitted the report.",
        choice_d: "He will ask the professor for help.",
        correct_choice: "B",
        explanation: "男性の発言は締め切りに間に合わない可能性を示しています。",
        wrong_reason_a: "課題を忘れたという発言はありません。",
        wrong_reason_c: "レポートをすでに提出したとは述べていません。",
        wrong_reason_d: "教授に助けを求めるとは言っていません。"
      },
      {
        tag: "shortConv",
        question_text: "What is the woman's problem?",
        question_audio_url: audio_url,
        choice_a: "She missed the lecture.",
        choice_b: "She lost her notes.",
        choice_c: "She cannot find the classroom.",
        choice_d: "She does not understand the material.",
        correct_choice: "A",
        explanation: "女性は講義を欠席したことを示唆しています。",
        wrong_reason_b: "ノートを失くしたという話は出ていません。",
        wrong_reason_c: "教室が見つからない問題ではありません。",
        wrong_reason_d: "内容が理解できないとは述べていません。"
      },
      {
        tag: "shortConv",
        question_text: "What does the woman suggest the man do?",
        question_audio_url: audio_url,
        choice_a: "Talk to the professor after class.",
        choice_b: "Study with a classmate.",
        choice_c: "Check the course website.",
        choice_d: "Read the textbook again.",
        correct_choice: "C",
        explanation: "女性はコースウェブサイトで確認するよう勧めています。",
        wrong_reason_a: "授業後に教授と話すとは提案していません。",
        wrong_reason_b: "クラスメートと勉強するという提案ではありません。",
        wrong_reason_d: "教科書を再度読むよう勧めてはいません。"
      },
      {
        tag: "shortConv",
        question_text: "What can be inferred about the man?",
        question_audio_url: audio_url,
        choice_a: "He is a graduate student.",
        choice_b: "He is unfamiliar with the campus.",
        choice_c: "He has been to the library before.",
        choice_d: "He does not have a student ID.",
        correct_choice: "B",
        explanation: "男性のキャンパスへの不慣れさが会話から読み取れます。",
        wrong_reason_a: "大学院生であるという情報はありません。",
        wrong_reason_c: "以前図書館に行ったという発言はありません。",
        wrong_reason_d: "学生証を持っていないとは述べられていません。"
      },
      {
        tag: "shortConv",
        question_text: "What does the woman say about the exam?",
        question_audio_url: audio_url,
        choice_a: "It has been postponed.",
        choice_b: "It covers three chapters.",
        choice_c: "It will be held online.",
        choice_d: "It is open book.",
        correct_choice: "A",
        explanation: "試験が延期されたと女性は述べています。",
        wrong_reason_b: "3章分が範囲という情報は出ていません。",
        wrong_reason_c: "オンライン実施とは述べられていません。",
        wrong_reason_d: "持ち込み可とは言っていません。"
      }
    ]
  )

  # Listening Part B (longConv) – 2 questions
  create_diagnostic_set!(
    diagnostic: diagnostic1,
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
        wrong_reason_a: "週末の予定は主題ではありません。",
        wrong_reason_c: "奨学金の話は会話に登場しません。",
        wrong_reason_d: "クラブの立ち上げ方は無関係です。"
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
        explanation: "女性はスライド作成を引き受けています。",
        wrong_reason_a: "データ収集は女性が担当とは述べていません。",
        wrong_reason_b: "イントロ執筆を引き受けるとは言っていません。",
        wrong_reason_d: "一人で発表するとは述べていません。"
      }
    ]
  )

  # Listening Part C (talk) – 2 questions
  create_diagnostic_set!(
    diagnostic: diagnostic1,
    section_type: "listening",
    part_type: "part_c",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "talk",
        question_text: "What is the main topic of the talk?",
        question_audio_url: audio_url,
        choice_a: "The history of the Internet.",
        choice_b: "Social media and mental health.",
        choice_c: "Online privacy laws.",
        choice_d: "Digital literacy in schools.",
        correct_choice: "B",
        explanation: "講義はソーシャルメディアとメンタルヘルスの関連を中心に論じています。",
        wrong_reason_a: "インターネットの歴史は主題ではありません。",
        wrong_reason_c: "プライバシー法については言及されていません。",
        wrong_reason_d: "学校でのデジタルリテラシーは主題ではありません。"
      },
      {
        tag: "talk",
        question_text: "According to the speaker, what is one effect of excessive social media use?",
        question_audio_url: audio_url,
        choice_a: "Improved academic performance.",
        choice_b: "Increased feelings of loneliness.",
        choice_c: "Better communication skills.",
        choice_d: "Reduced screen time.",
        correct_choice: "B",
        explanation: "講師は過度なSNS使用が孤独感を高めると述べています。",
        wrong_reason_a: "学業成績の向上は述べられていません。",
        wrong_reason_c: "コミュニケーションスキル向上は言及されていません。",
        wrong_reason_d: "スクリーンタイムの減少は述べられていません。"
      }
    ]
  )

  # Structure Part B – Written Expression (8 questions)
  create_diagnostic_set!(
    diagnostic: diagnostic1,
    section_type: "structure",
    part_type: "part_b",
    set_number: 1,
    questions: [
      {
        tag: "verbForm",
        question_text: "The committee has (A)decided to postponing (B)the annual conference (C)due to the (D)ongoing renovation.",
        choice_a: "decided",
        choice_b: "the annual conference",
        choice_c: "due to the",
        choice_d: "ongoing renovation",
        correct_choice: "A",
        explanation: '"decided to postponing" は誤り。"decide to" の後には動詞の原形が来るため "decided to postpone" が正しい。',
        wrong_reason_b: "the annual conferenceは名詞句として正しい。",
        wrong_reason_c: "due to theは前置詞句として正しい。",
        wrong_reason_d: "ongoingは形容詞として正しく使われています。"
      },
      {
        tag: "nounPronoun",
        question_text: "Each of the students (A)are required to (B)submit (C)their reports (D)by Friday.",
        choice_a: "are required",
        choice_b: "submit",
        choice_c: "their reports",
        choice_d: "by Friday",
        correct_choice: "A",
        explanation: '"Each of" は単数扱いのため "is required" が正しい。',
        wrong_reason_b: "submitは動詞として正しい用法です。",
        wrong_reason_c: "theirはstudentsを受けており問題ありません。",
        wrong_reason_d: "by Fridayは正しい時を表す前置詞句です。"
      },
      {
        tag: "modifierConnect",
        question_text: "The scientist (A)explained the results (B)clear and (C)confidently to the (D)audience.",
        choice_a: "explained the results",
        choice_b: "clear",
        choice_c: "confidently",
        choice_d: "audience",
        correct_choice: "B",
        explanation: '"clear" は副詞 "clearly" であるべき。動詞 explained を修飾するため副詞が必要。',
        wrong_reason_a: "explained the resultsは正しいSV目的語構造です。",
        wrong_reason_c: "confidentlyは正しい副詞形です。",
        wrong_reason_d: "audienceは名詞として正しい。"
      },
      {
        tag: "verbForm",
        question_text: "The report (A)was (B)wrote by three (C)senior researchers (D)at the institute.",
        choice_a: "was",
        choice_b: "wrote",
        choice_c: "senior researchers",
        choice_d: "at the institute",
        correct_choice: "B",
        explanation: '"was wrote" は誤り。受動態は "was written" が正しい。',
        wrong_reason_a: "wasは受動態の助動詞として正しい。",
        wrong_reason_c: "senior researchersは正しい名詞句です。",
        wrong_reason_d: "at the instituteは正しい場所を示す句です。"
      },
      {
        tag: "nounPronoun",
        question_text: "Neither the manager nor the employees (A)was (B)informed about (C)the policy (D)changes.",
        choice_a: "was",
        choice_b: "informed",
        choice_c: "the policy",
        choice_d: "changes",
        correct_choice: "A",
        explanation: '"Neither A nor B" で動詞はBに一致するため "were" が正しい。',
        wrong_reason_b: "informedは過去分詞として正しい。",
        wrong_reason_c: "the policyは正しい名詞句の一部です。",
        wrong_reason_d: "changesはpolicyを修飾する名詞として正しい。"
      },
      {
        tag: "modifierConnect",
        question_text: "The new regulation, (A)which was (B)announced recent, (C)affects all (D)international students.",
        choice_a: "which was",
        choice_b: "announced recent",
        choice_c: "affects all",
        choice_d: "international students",
        correct_choice: "B",
        explanation: '"recent" は副詞 "recently" であるべき。動詞 announced を修飾するため。',
        wrong_reason_a: "which wasは関係詞節の正しい始まりです。",
        wrong_reason_c: "affects allは正しい動詞と目的語の組み合わせです。",
        wrong_reason_d: "international studentsは正しい名詞句です。"
      },
      {
        tag: "verbForm",
        question_text: "By the time the guests (A)arrived, the chef (B)has already (C)prepared (D)the entire meal.",
        choice_a: "arrived",
        choice_b: "has already",
        choice_c: "prepared",
        choice_d: "the entire meal",
        correct_choice: "B",
        explanation: '"By the time + 過去形" の場合、主節は過去完了 "had already" が正しい。',
        wrong_reason_a: "arrivedは過去形として正しい。",
        wrong_reason_c: "preparedは過去完了の一部として正しい形です。",
        wrong_reason_d: "the entire mealは正しい目的語です。"
      },
      {
        tag: "nounPronoun",
        question_text: "The professor asked the class to hand (A)in (B)their (C)essay before (D)leave the room.",
        choice_a: "in",
        choice_b: "their",
        choice_c: "essay",
        choice_d: "leave",
        correct_choice: "D",
        explanation: '"before leave" は誤り。前置詞 before の後には動名詞 "leaving" が必要。',
        wrong_reason_a: "inはhand inの慣用句として正しい。",
        wrong_reason_b: "theirはclassを受ける所有格として正しい。",
        wrong_reason_c: "essayは正しい目的語です。"
      }
    ]
  )

  # Reading Passage 1 (10 questions)
  passage1_text = <<~PASSAGE
    The concept of "flow," introduced by psychologist Mihaly Csikszentmihalyi, describes a mental state
    in which a person is fully immersed in an activity, experiencing energized focus and enjoyment.
    Flow occurs when the challenge of a task matches the individual's skill level — too easy, and
    boredom sets in; too difficult, and anxiety takes over. Research has shown that people in flow states
    report higher levels of creativity, productivity, and overall well-being. Athletes describe it as
    being "in the zone," while musicians refer to it as playing effortlessly. Although flow can occur
    in any domain — from surgery to chess — it is most commonly reported during activities that require
    skill, concentration, and clear goals. Organizations have begun applying flow theory to workplace
    design, restructuring tasks to promote deeper engagement. Critics argue, however, that not all
    productive work is enjoyable, and that overemphasizing flow may neglect the value of deliberate,
    effortful practice.
  PASSAGE

  create_diagnostic_set!(
    diagnostic: diagnostic1,
    section_type: "reading",
    part_type: "passages",
    set_number: 1,
    passage: passage1_text,
    passage_theme: "Psychology",
    questions: [
      {
        tag: "fact",
        question_text: "According to the passage, who introduced the concept of flow?",
        choice_a: "A sports psychologist",
        choice_b: "Mihaly Csikszentmihalyi",
        choice_c: "A neuroscientist",
        choice_d: "An organizational consultant",
        correct_choice: "B",
        explanation: "本文第1文に Mihaly Csikszentmihalyi が flow の概念を導入したと明記されています。",
        wrong_reason_a: "スポーツ心理学者とは述べられていません。",
        wrong_reason_c: "神経科学者とは述べられていません。",
        wrong_reason_d: "組織コンサルタントとは述べられていません。"
      },
      {
        tag: "fact",
        question_text: "According to the passage, when does boredom occur?",
        choice_a: "When the task is too difficult.",
        choice_b: "When the person is distracted.",
        choice_c: "When the task is too easy.",
        choice_d: "When goals are unclear.",
        correct_choice: "C",
        explanation: "本文に「too easy, and boredom sets in」と明記されています。",
        wrong_reason_a: "難しすぎる場合は不安（anxiety）が生じると述べられています。",
        wrong_reason_b: "気が散ることによる退屈は本文に書かれていません。",
        wrong_reason_d: "目標が不明確な場合についての記述ではありません。"
      },
      {
        tag: "inference",
        question_text: "What can be inferred about athletes who are \"in the zone\"?",
        choice_a: "They are experiencing a flow state.",
        choice_b: "They are performing below their skill level.",
        choice_c: "They feel anxious about the competition.",
        choice_d: "They are using a new training technique.",
        correct_choice: "A",
        explanation: "本文はアスリートが「in the zone」と表現する状態を flow と同一視しています。",
        wrong_reason_b: "スキルレベル以下のパフォーマンスという記述はありません。",
        wrong_reason_c: "不安を感じているという文脈ではありません。",
        wrong_reason_d: "新しいトレーニング技術の話ではありません。"
      },
      {
        tag: "vocab",
        question_text: "The word \"immersed\" in paragraph 1 is closest in meaning to",
        choice_a: "confused",
        choice_b: "absorbed",
        choice_c: "exhausted",
        choice_d: "distracted",
        correct_choice: "B",
        explanation: '"immersed" は「完全に没頭した」という意味で、"absorbed" が最も近い。',
        wrong_reason_a: "confusedは「混乱した」という意味で異なります。",
        wrong_reason_c: "exhaustedは「疲れ果てた」という意味で異なります。",
        wrong_reason_d: "distractedは「気が散った」という意味で正反対です。"
      },
      {
        tag: "inference",
        question_text: "Which of the following best describes the author's tone toward flow theory?",
        choice_a: "Strongly critical.",
        choice_b: "Completely supportive.",
        choice_c: "Balanced and informative.",
        choice_d: "Dismissive.",
        correct_choice: "C",
        explanation: "著者は flow の利点を説明しつつ批判的な見方も紹介しており、バランスのとれたトーンです。",
        wrong_reason_a: "強い批判的トーンではなく、利点も述べています。",
        wrong_reason_b: "批評家の意見も紹介しており、完全な支持ではありません。",
        wrong_reason_d: "無視するようなトーンではありません。"
      },
      {
        tag: "fact",
        question_text: "According to the passage, in which domains can flow occur?",
        choice_a: "Only in sports.",
        choice_b: "Only in creative arts.",
        choice_c: "Only in academic settings.",
        choice_d: "In any domain requiring skill and concentration.",
        correct_choice: "D",
        explanation: "本文に「flow can occur in any domain — from surgery to chess」と明記されています。",
        wrong_reason_a: "スポーツだけに限定されていません。",
        wrong_reason_b: "創造的芸術のみとは述べられていません。",
        wrong_reason_c: "学術的な場だけとは記述されていません。"
      },
      {
        tag: "vocab",
        question_text: "The word \"deliberate\" in the last sentence is closest in meaning to",
        choice_a: "accidental",
        choice_b: "intentional",
        choice_c: "creative",
        choice_d: "rapid",
        correct_choice: "B",
        explanation: '"deliberate" は「意図的な、意識的な」という意味で "intentional" が最も近い。',
        wrong_reason_a: "accidentalは「偶然の」という意味で正反対です。",
        wrong_reason_c: "creativeは「創造的な」という意味で異なります。",
        wrong_reason_d: "rapidは「速い」という意味で異なります。"
      },
      {
        tag: "inference",
        question_text: "What do critics of flow theory most likely believe?",
        choice_a: "Flow is impossible to achieve in the workplace.",
        choice_b: "Hard work does not always need to be enjoyable.",
        choice_c: "Flow states are harmful to productivity.",
        choice_d: "Flow theory applies only to athletes.",
        correct_choice: "B",
        explanation: "批評家は「生産的な仕事がすべて楽しいわけではない」と述べており、努力の価値を強調しています。",
        wrong_reason_a: "職場でのflow達成が不可能とは述べていません。",
        wrong_reason_c: "flowが生産性に有害とは述べていません。",
        wrong_reason_d: "アスリートのみに適用されるとは述べていません。"
      },
      {
        tag: "fact",
        question_text: "According to the passage, what have organizations done with flow theory?",
        choice_a: "Rejected it as impractical.",
        choice_b: "Applied it to workplace design.",
        choice_c: "Used it to evaluate employee performance.",
        choice_d: "Integrated it into hiring processes.",
        correct_choice: "B",
        explanation: "本文に「Organizations have begun applying flow theory to workplace design」と明記されています。",
        wrong_reason_a: "非現実的として拒否したとは述べていません。",
        wrong_reason_c: "従業員評価への使用は述べられていません。",
        wrong_reason_d: "採用プロセスへの統合は述べられていません。"
      },
      {
        tag: "inference",
        question_text: "What is the most likely purpose of this passage?",
        choice_a: "To argue that flow is superior to deliberate practice.",
        choice_b: "To provide an overview of flow theory and its applications.",
        choice_c: "To criticize the use of psychology in the workplace.",
        choice_d: "To describe Csikszentmihalyi's personal life.",
        correct_choice: "B",
        explanation: "本文はflow理論の概要、応用例、および批判をバランスよく説明しており、概説を目的としています。",
        wrong_reason_a: "deliberate practiceよりflowが優れているとは主張していません。",
        wrong_reason_c: "職場での心理学利用への批判が目的ではありません。",
        wrong_reason_d: "Csikszentmihalyiの個人的な生活については述べていません。"
      }
    ]
  )

  # Reading Passage 2 (10 questions)
  passage2_text = <<~PASSAGE
    Coral reefs, often called the "rainforests of the sea," support approximately 25 percent of all
    marine species despite covering less than 1 percent of the ocean floor. These ecosystems are built
    by tiny organisms called coral polyps, which secrete calcium carbonate to form the hard structures
    we recognize as reefs. Coral reefs thrive in warm, clear, shallow waters where sunlight can
    penetrate. A critical relationship exists between corals and photosynthetic algae known as
    zooxanthellae, which live within coral tissues and provide up to 90 percent of the coral's
    energy through photosynthesis. When ocean temperatures rise even slightly, corals expel their
    algae in a process known as coral bleaching, leaving the reef white and vulnerable. Prolonged
    bleaching events, increasingly common due to climate change, can lead to coral death. While
    some recovery is possible if temperatures stabilize, repeated bleaching events have caused
    widespread, permanent damage to reefs worldwide, threatening the biodiversity they support
    and the millions of people who depend on them for food and coastal protection.
  PASSAGE

  create_diagnostic_set!(
    diagnostic: diagnostic1,
    section_type: "reading",
    part_type: "passages",
    set_number: 2,
    passage: passage2_text,
    passage_theme: "Marine Biology",
    questions: [
      {
        tag: "fact",
        question_text: "According to the passage, what percentage of marine species do coral reefs support?",
        choice_a: "Less than 1 percent.",
        choice_b: "About 10 percent.",
        choice_c: "Approximately 25 percent.",
        choice_d: "More than 50 percent.",
        correct_choice: "C",
        explanation: "本文第1文に「approximately 25 percent of all marine species」と明記されています。",
        wrong_reason_a: "1%以下はサンゴ礁が占める海底面積の説明です。",
        wrong_reason_b: "10%という数字は本文に登場しません。",
        wrong_reason_d: "50%以上とは述べられていません。"
      },
      {
        tag: "vocab",
        question_text: "The word \"secrete\" in paragraph 1 is closest in meaning to",
        choice_a: "absorb",
        choice_b: "dissolve",
        choice_c: "release",
        choice_d: "reflect",
        correct_choice: "C",
        explanation: '"secrete" は「分泌する、放出する」という意味で "release" が最も近い。',
        wrong_reason_a: "absorbは「吸収する」という意味で正反対です。",
        wrong_reason_b: "dissolveは「溶かす」という意味で異なります。",
        wrong_reason_d: "reflectは「反射する」という意味で異なります。"
      },
      {
        tag: "fact",
        question_text: "According to the passage, what do zooxanthellae provide to corals?",
        choice_a: "Structural support.",
        choice_b: "Up to 90 percent of their energy.",
        choice_c: "Protection from predators.",
        choice_d: "A source of calcium carbonate.",
        correct_choice: "B",
        explanation: "本文に「provide up to 90 percent of the coral's energy through photosynthesis」と明記されています。",
        wrong_reason_a: "構造的サポートは述べられていません。",
        wrong_reason_c: "捕食者からの保護は述べられていません。",
        wrong_reason_d: "炭酸カルシウムはサンゴポリプが分泌するものです。"
      },
      {
        tag: "fact",
        question_text: "What happens when ocean temperatures rise?",
        choice_a: "Coral polyps reproduce rapidly.",
        choice_b: "Zooxanthellae produce more energy.",
        choice_c: "Corals expel their algae.",
        choice_d: "Reefs expand in size.",
        correct_choice: "C",
        explanation: "本文に「corals expel their algae in a process known as coral bleaching」と明記されています。",
        wrong_reason_a: "急速に繁殖するとは述べられていません。",
        wrong_reason_b: "より多くのエネルギーを生産するとは述べていません。",
        wrong_reason_d: "礁が拡大するとは述べていません。"
      },
      {
        tag: "vocab",
        question_text: "The word \"vulnerable\" as used in the passage means",
        choice_a: "colorful",
        choice_b: "transparent",
        choice_c: "at risk",
        choice_d: "productive",
        correct_choice: "C",
        explanation: '"vulnerable" は「傷つきやすい、危険にさらされた」という意味で "at risk" が最も近い。',
        wrong_reason_a: "colorfulは「色鮮やか」という意味で異なります。",
        wrong_reason_b: "transparentは「透明な」という意味で異なります。",
        wrong_reason_d: "productiveは「生産的な」という意味で異なります。"
      },
      {
        tag: "inference",
        question_text: "What can be inferred about coral bleaching events?",
        choice_a: "They are becoming less frequent.",
        choice_b: "They are caused mainly by pollution.",
        choice_c: "They are increasingly linked to climate change.",
        choice_d: "They only affect shallow water corals.",
        correct_choice: "C",
        explanation: "本文に「increasingly common due to climate change」と述べられており、気候変動との関連が示唆されています。",
        wrong_reason_a: "減少しているとは述べられておらず、むしろ増加しています。",
        wrong_reason_b: "主に汚染が原因とは述べられていません。",
        wrong_reason_d: "浅い水域のサンゴだけに影響するとは限定されていません。"
      },
      {
        tag: "inference",
        question_text: "What does the passage imply about coral recovery?",
        choice_a: "It always occurs after bleaching.",
        choice_b: "It is impossible once bleaching begins.",
        choice_c: "It depends on whether temperatures stabilize.",
        choice_d: "It requires human intervention.",
        correct_choice: "C",
        explanation: "本文に「some recovery is possible if temperatures stabilize」と条件付きで回復の可能性が述べられています。",
        wrong_reason_a: "必ず回復するとは述べていません。",
        wrong_reason_b: "回復が完全に不可能とは述べていません。",
        wrong_reason_d: "人間の介入が必要とは述べていません。"
      },
      {
        tag: "fact",
        question_text: "According to the passage, what percentage of the ocean floor do coral reefs cover?",
        choice_a: "25 percent.",
        choice_b: "Less than 1 percent.",
        choice_c: "About 10 percent.",
        choice_d: "50 percent.",
        correct_choice: "B",
        explanation: "本文に「covering less than 1 percent of the ocean floor」と明記されています。",
        wrong_reason_a: "25%は海洋生物種のサポート割合の説明です。",
        wrong_reason_c: "10%という数字は本文に登場しません。",
        wrong_reason_d: "50%とは述べられていません。"
      },
      {
        tag: "inference",
        question_text: "Who, according to the passage, is threatened by reef damage?",
        choice_a: "Only marine biologists.",
        choice_b: "Deep-sea fishermen exclusively.",
        choice_c: "Millions of people who rely on reefs for food and protection.",
        choice_d: "Tourists visiting coral reefs.",
        correct_choice: "C",
        explanation: "本文末に「millions of people who depend on them for food and coastal protection」と述べられています。",
        wrong_reason_a: "海洋生物学者のみとは述べていません。",
        wrong_reason_b: "深海漁師のみとは述べていません。",
        wrong_reason_d: "観光客については言及されていません。"
      },
      {
        tag: "vocab",
        question_text: "The phrase \"prolonged bleaching events\" means",
        choice_a: "Bleaching that occurs very quickly.",
        choice_b: "Bleaching that lasts for an extended period.",
        choice_c: "Bleaching caused by human activity.",
        choice_d: "Bleaching that affects only one species.",
        correct_choice: "B",
        explanation: '"prolonged" は「長期にわたる」という意味で、長時間続く白化現象を指します。',
        wrong_reason_a: "非常に速く起こるとは正反対の意味です。",
        wrong_reason_c: "人間活動による白化とは限定されていません。",
        wrong_reason_d: "一種だけに影響するとは述べられていません。"
      }
    ]
  )

  puts "Diagnostic seed finished: #{diagnostic1.title}"

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

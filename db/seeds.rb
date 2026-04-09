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

  def create_exercise_set!(section_type:, part_type:, set_number:, passage: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
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

  def create_mock_set!(mock:, section_type:, part_type:, set_number:, passage: nil, audio_url: nil, scripts: DEFAULT_SCRIPTS, questions:)
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

  (1..10).each do |i|
    user = User.find_or_initialize_by(email: "testuser#{i}@gmail.com")
    user.password = "testuser#{i}"
    user.password_confirmation = "testuser#{i}"
    user.terms_agreed = true
    user.confirmed_at ||= Time.current
    user.save!
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
    part_type: "part_a",
    set_number: 2,
    questions: [
      {
        tag: "shortConv",
        question_text: "What is the man concerned about?",
        question_audio_url: audio_url,
        choice_a: "Missing the deadline.",
        choice_b: "Forgetting his umbrella.",
        choice_c: "Losing his student ID.",
        choice_d: "Getting a lower grade.",
        correct_choice: "A",
        explanation: "期限に間に合うかどうかを気にしています。",
        wrong_reason_b: "傘についての言及は会話に全くありません。",
        wrong_reason_c: "学生証の紛失は会話の話題ではありません。",
        wrong_reason_d: "成績への不安は会話から読み取れません。"
      },
      {
        tag: "shortConv",
        question_text: "What does the woman suggest?",
        question_audio_url: audio_url,
        choice_a: "Submitting online.",
        choice_b: "Waiting until tomorrow.",
        choice_c: "Asking for a refund.",
        choice_d: "Changing the course.",
        correct_choice: "A",
        explanation: "オンライン提出が可能だと示しています。",
        wrong_reason_b: "明日まで待つという提案は会話中にありません。",
        wrong_reason_c: "払い戻しの話題は全く出ていません。",
        wrong_reason_d: "授業を変更するという選択肢は提案されていません。"
      },
      {
        tag: "shortConv",
        question_text: "What will they do later?",
        question_audio_url: audio_url,
        choice_a: "Meet at the library.",
        choice_b: "Go to the gym.",
        choice_c: "Visit the museum.",
        choice_d: "Take a taxi.",
        correct_choice: "A",
        explanation: "後で図書館で会う流れです。",
        wrong_reason_b: "ジムに行くという計画は会話に出てきません。",
        wrong_reason_c: "博物館を訪れるという話題は会話中にありません。",
        wrong_reason_d: "タクシーに乗るという話は会話に含まれていません。"
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
        question_text: "The Eiffel Tower ------- in 1889 for the World's Fair.",
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
        question_text: "If I ------- more time, I would travel more often.",
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
        question_text: "The report must ------- by Friday.",
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
        question_text: "The (A) beautifully flowers (B) in the garden (C) are blooming (D) now.",
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
        question_text: "She (A) suggested me (B) to take (C) a short break (D).",
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
        question_text: "I (A) have lived (B) here (C) since five years (D).",
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

  create_exercise_set!(
    section_type: "reading",
    part_type: "passages",
    set_number: 2,
    passage: <<~TEXT,
      Many people find that establishing a regular study routine improves retention.
      Short, consistent sessions often lead to better results than infrequent long sessions.
    TEXT
    questions: [
      {
        tag: "inference",
        question_text: "What does the passage suggest about study routines?",
        choice_a: "They do not affect retention.",
        choice_b: "Long sessions are always best.",
        choice_c: "Regular routines can improve retention.",
        choice_d: "Studying should be avoided.",
        correct_choice: "C",
        explanation: "定期的な学習が定着に役立つと述べています。",
        wrong_reason_a: "本文は学習ルーティンが定着に影響すると明確に述べており、影響なしとは逆の内容です。",
        wrong_reason_b: "本文は長時間の学習より短く継続的な学習を推奨しており、正反対の内容です。",
        wrong_reason_d: "学習を避けるよう勧める内容は本文に全くありません。"
      },
      {
        tag: "fact",
        question_text: "What kind of sessions are recommended?",
        choice_a: "Short and consistent",
        choice_b: "Only long sessions",
        choice_c: "Only weekend sessions",
        choice_d: "Late-night sessions",
        correct_choice: "A",
        explanation: "短く継続的な学習が良いと説明しています。",
        wrong_reason_b: "本文は長時間のセッションより短く継続的なものを勧めており、長時間のみとは逆です。",
        wrong_reason_c: "週末だけの学習については本文中に言及がありません。",
        wrong_reason_d: "深夜の学習セッションは本文のテーマではありません。"
      },
      {
        tag: "fact",
        question_text: "Which is contrasted in the passage?",
        choice_a: "Morning vs night",
        choice_b: "Short consistent vs infrequent long",
        choice_c: "Reading vs listening",
        choice_d: "Online vs offline",
        correct_choice: "B",
        explanation: "短く継続 vs 長く不定期 の対比です。",
        wrong_reason_a: "朝と夜の対比は本文中に示されていません。",
        wrong_reason_c: "読むことと聴くことの対比は本文のテーマではありません。",
        wrong_reason_d: "オンラインとオフラインの対比は本文に含まれていません。"
      }
    ]
  )

  # --- Fillers to reach 10 sets for each part ---

  # Listening Part A (3-10)
  (3..10).each do |i|
    create_exercise_set!(
      section_type: "listening",
      part_type: "part_a",
      set_number: i,
      questions: 3.times.map { |j|
        {
          tag: "shortConv",
          question_text: "Sample Listening Part A Question #{i}-#{j+1}",
          audio_url: audio_url,
          choice_a: "Option A",
          choice_b: "Option B",
          choice_c: "Option C",
          choice_d: "Option D",
          correct_choice: ["A", "B", "C", "D"].sample,
          explanation: "Sample explanation for listening part a set #{i} question #{j+1}"
        }
      }
    )
  end

  # Listening Part B (2-10)
  (2..10).each do |i|
    create_exercise_set!(
      section_type: "listening",
      part_type: "part_b",
      set_number: i,
      audio_url: audio_url,
      questions: 2.times.map { |j|
        {
          tag: "longConv",
          question_text: "Sample Listening Part B Question #{i}-#{j+1}",
          audio_url: audio_url,
          choice_a: "Option A",
          choice_b: "Option B",
          choice_c: "Option C",
          choice_d: "Option D",
          correct_choice: ["A", "B", "C", "D"].sample,
          explanation: "Sample explanation for listening part b set #{i} question #{j+1}"
        }
      }
    )
  end

  # Listening Part C (2-10)
  (2..10).each do |i|
    create_exercise_set!(
      section_type: "listening",
      part_type: "part_c",
      set_number: i,
      audio_url: audio_url,
      questions: 2.times.map { |j|
        {
          tag: "talk",
          question_text: "Sample Listening Part C Question #{i}-#{j+1}",
          audio_url: audio_url,
          choice_a: "Option A",
          choice_b: "Option B",
          choice_c: "Option C",
          choice_d: "Option D",
          correct_choice: ["A", "B", "C", "D"].sample,
          explanation: "Sample explanation for listening part c set #{i} question #{j+1}"
        }
      }
    )
  end

  # Structure Part A (2-10)
  (2..10).each do |i|
    create_exercise_set!(
      section_type: "structure",
      part_type: "part_a",
      set_number: i,
      questions: 3.times.map { |j|
        {
          tag: "verbForm",
          question_text: "Sample Structure Part A Question #{i}-#{j+1} -------",
          choice_a: "Option A",
          choice_b: "Option B",
          choice_c: "Option C",
          choice_d: "Option D",
          correct_choice: ["A", "B", "C", "D"].sample,
          explanation: "Sample explanation for structure part a set #{i} question #{j+1}"
        }
      }
    )
  end

  # Structure Part B (2-10)
  (2..10).each do |i|
    create_exercise_set!(
      section_type: "structure",
      part_type: "part_b",
      set_number: i,
      questions: 3.times.map { |j|
        {
          tag: "sentenceStruct",
          question_text: "Sample Structure Part B (A) Question (B) #{i}-#{j+1} (C) identify (D) error.",
          choice_a: "A",
          choice_b: "B",
          choice_c: "C",
          choice_d: "D",
          correct_choice: ["A", "B", "C", "D"].sample,
          explanation: "Sample explanation for structure part b set #{i} question #{j+1}"
        }
      }
    )
  end

  # Reading Passages (3..10)
  (3..10).each do |i|
    create_exercise_set!(
      section_type: "reading",
      part_type: "passages",
      set_number: i,
      passage: "Sample passage for Set #{i}. This is a placeholder text for reading comprehension exercise.",
      questions: 3.times.map { |j|
        {
          tag: "fact",
          question_text: "Sample Reading Question #{i}-#{j+1}",
          choice_a: "Option A",
          choice_b: "Option B",
          choice_c: "Option C",
          choice_d: "Option D",
          correct_choice: ["A", "B", "C", "D"].sample,
          explanation: "Sample explanation for reading comprehension set #{i} question #{j+1}"
        }
      }
    )
  end

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
        question_text: "The Eiffel Tower ------- in 1889 for the World's Fair.",
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
        question_text: "If I ------- more time, I would travel more often.",
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
        question_text: "The report must ------- by Friday.",
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

  mock2 = Mock.create!(title: "第2回 模擬試験")

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        tag: "shortConv",
        question_text: "What does the man suggest the woman do?",
        question_audio_url: audio_url,
        choice_a: "Apply for a scholarship.",
        choice_b: "Talk to the professor directly.",
        choice_c: "Drop the course.",
        choice_d: "Visit the tutoring center.",
        correct_choice: "D",
        explanation: "男性はチュータリングセンターの利用を勧めています。",
        wrong_reason_a: "奨学金の申請を勧める発言は会話中にありません。",
        wrong_reason_b: "教授に直接話すよう提案したという内容は会話に含まれていません。",
        wrong_reason_c: "授業を取り消すよう勧める発言は会話にありません。"
      },
      {
        tag: "shortConv",
        question_text: "What is the woman's problem?",
        question_audio_url: audio_url,
        choice_a: "She lost her textbook.",
        choice_b: "She missed the midterm.",
        choice_c: "She is struggling with chemistry.",
        choice_d: "She cannot register for classes.",
        correct_choice: "C",
        explanation: "化学の授業に苦労していることが会話から分かります。",
        wrong_reason_a: "教科書を失くしたという話は会話中に出てきません。",
        wrong_reason_b: "中間試験を欠席したという内容は会話にありません。",
        wrong_reason_d: "授業登録ができないという問題は会話のテーマではありません。"
      },
      {
        tag: "shortConv",
        question_text: "What will the woman probably do next?",
        question_audio_url: audio_url,
        choice_a: "Go to the library.",
        choice_b: "Call her parents.",
        choice_c: "Visit the tutoring center.",
        choice_d: "Study alone in her room.",
        correct_choice: "C",
        explanation: "男性の提案を受け入れてチュータリングセンターへ向かうと考えられます。",
        wrong_reason_a: "図書館に行くという流れは会話から読み取れません。",
        wrong_reason_b: "親に電話するという話は会話に全く出てきません。",
        wrong_reason_d: "一人で部屋で勉強するという意図は会話から示されていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_a",
    set_number: 2,
    questions: [
      {
        tag: "shortConv",
        question_text: "What does the woman mean?",
        question_audio_url: audio_url,
        choice_a: "She is very hungry.",
        choice_b: "The cafeteria is not open yet.",
        choice_c: "She would rather not eat at the cafeteria.",
        choice_d: "The food at the cafeteria is expensive.",
        correct_choice: "C",
        explanation: "発言から、カフェテリアへの否定的なニュアンスが読み取れます。",
        wrong_reason_a: "非常に空腹だという感情は会話中で明示されていません。",
        wrong_reason_b: "カフェテリアがまだ開いていないという情報は会話中に含まれていません。",
        wrong_reason_d: "食事が高いという話は会話の中で触れられていません。"
      },
      {
        tag: "shortConv",
        question_text: "What does the man suggest?",
        question_audio_url: audio_url,
        choice_a: "Trying a restaurant nearby.",
        choice_b: "Cooking at home.",
        choice_c: "Skipping lunch.",
        choice_d: "Ordering delivery.",
        correct_choice: "A",
        explanation: "近くのレストランを試すことを提案しています。",
        wrong_reason_b: "家で料理することを提案したという内容は会話にありません。",
        wrong_reason_c: "昼食を抜くよう勧める発言は会話中にありません。",
        wrong_reason_d: "デリバリーを注文する提案は会話に登場しません。"
      },
      {
        tag: "shortConv",
        question_text: "How does the woman feel at the end?",
        question_audio_url: audio_url,
        choice_a: "Disappointed.",
        choice_b: "Uncertain.",
        choice_c: "Agreeable.",
        choice_d: "Frustrated.",
        correct_choice: "C",
        explanation: "会話の最後で女性は提案に同意しています。",
        wrong_reason_a: "失望した様子は会話の最後に表れていません。",
        wrong_reason_b: "迷っている様子ではなく、はっきりと同意しています。",
        wrong_reason_d: "苛立ちの感情は会話の終わりには見られません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_a",
    set_number: 3,
    questions: [
      {
        tag: "shortConv",
        question_text: "What does the professor imply?",
        question_audio_url: audio_url,
        choice_a: "The assignment is due today.",
        choice_b: "Students should start early.",
        choice_c: "The exam has been cancelled.",
        choice_d: "Extra credit is not available.",
        correct_choice: "B",
        explanation: "早めに始めるべきだという示唆が含まれています。",
        wrong_reason_a: "課題が今日締め切りとは述べられていません。",
        wrong_reason_c: "試験のキャンセルについては会話中で全く触れられていません。",
        wrong_reason_d: "追加点の有無は会話の話題に含まれていません。"
      },
      {
        tag: "shortConv",
        question_text: "What is the student's concern?",
        question_audio_url: audio_url,
        choice_a: "Finding a study partner.",
        choice_b: "Understanding the assignment topic.",
        choice_c: "Meeting the word count requirement.",
        choice_d: "Accessing the online library.",
        correct_choice: "B",
        explanation: "課題のトピックについて理解できていないことを心配しています。",
        wrong_reason_a: "学習パートナーを探すことは会話の悩みとして示されていません。",
        wrong_reason_c: "文字数の要件については会話で言及されていません。",
        wrong_reason_d: "オンライン図書館へのアクセス問題は会話のテーマではありません。"
      },
      {
        tag: "shortConv",
        question_text: "What does the professor offer?",
        question_audio_url: audio_url,
        choice_a: "To extend the deadline.",
        choice_b: "To provide a sample paper.",
        choice_c: "To hold office hours tomorrow.",
        choice_d: "To assign a different topic.",
        correct_choice: "C",
        explanation: "翌日のオフィスアワーを設けると申し出ています。",
        wrong_reason_a: "締め切りの延長を申し出る発言は会話中にありません。",
        wrong_reason_b: "サンプル論文を提供するという申し出は会話に含まれていません。",
        wrong_reason_d: "別のトピックを割り当てるという提案は会話中で出てきません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_b",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "longConv",
        question_text: "What is the main topic of the conversation?",
        question_audio_url: audio_url,
        choice_a: "Planning a campus event.",
        choice_b: "Choosing a major.",
        choice_c: "Applying for graduate school.",
        choice_d: "Registering for next semester's classes.",
        correct_choice: "D",
        explanation: "来学期の履修登録について話し合っています。",
        wrong_reason_a: "キャンパスイベントの計画は会話のテーマではありません。",
        wrong_reason_b: "専攻の選択は会話の主題として示されていません。",
        wrong_reason_c: "大学院の出願については会話で触れられていません。"
      },
      {
        tag: "longConv",
        question_text: "What problem does the man mention?",
        question_audio_url: audio_url,
        choice_a: "A class he wants is already full.",
        choice_b: "He forgot his student ID.",
        choice_c: "His advisor is unavailable.",
        choice_d: "The online portal is down.",
        correct_choice: "A",
        explanation: "希望するクラスが満員であることを問題として挙げています。",
        wrong_reason_b: "学生証を忘れたという話は会話中に出てきません。",
        wrong_reason_c: "指導教員が不在という問題は会話で言及されていません。",
        wrong_reason_d: "オンラインポータルの障害については会話中で触れられていません。"
      },
      {
        tag: "longConv",
        question_text: "What does the woman recommend?",
        question_audio_url: audio_url,
        choice_a: "Contacting the registrar's office.",
        choice_b: "Joining the waitlist.",
        choice_c: "Taking an equivalent online course.",
        choice_d: "Asking the professor for permission.",
        correct_choice: "B",
        explanation: "ウェイティングリストに登録することを勧めています。",
        wrong_reason_a: "教務課に連絡することは女性の提案として示されていません。",
        wrong_reason_c: "同等のオンラインコースを受けるよう勧める発言はありません。",
        wrong_reason_d: "教授に許可を求めることは女性の推奨内容ではありません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_b",
    set_number: 2,
    audio_url: audio_url,
    questions: [
      {
        tag: "longConv",
        question_text: "What are the speakers preparing for?",
        question_audio_url: audio_url,
        choice_a: "A science fair.",
        choice_b: "A group presentation.",
        choice_c: "A study abroad application.",
        choice_d: "A campus orientation.",
        correct_choice: "B",
        explanation: "グループ発表の準備について話し合っています。",
        wrong_reason_a: "科学展示会の準備は会話のテーマではありません。",
        wrong_reason_c: "留学の申請は会話中で触れられていません。",
        wrong_reason_d: "キャンパスオリエンテーションの準備とは異なる内容です。"
      },
      {
        tag: "longConv",
        question_text: "Who will handle the data analysis?",
        question_audio_url: audio_url,
        choice_a: "The woman.",
        choice_b: "Both of them together.",
        choice_c: "The man.",
        choice_d: "A third group member.",
        correct_choice: "C",
        explanation: "男性がデータ分析を担当することになりました。",
        wrong_reason_a: "女性がデータ分析を担当するとは会話中で述べられていません。",
        wrong_reason_b: "二人で共同作業をするという合意は示されていません。",
        wrong_reason_d: "グループの3人目のメンバーが分析を担当するという内容はありません。"
      },
      {
        tag: "longConv",
        question_text: "When will they meet again?",
        question_audio_url: audio_url,
        choice_a: "Tomorrow morning.",
        choice_b: "Friday afternoon.",
        choice_c: "Next Monday.",
        choice_d: "Over the weekend.",
        correct_choice: "D",
        explanation: "週末に再び集まることで合意しています。",
        wrong_reason_a: "明日の朝に会う約束は会話中で交わされていません。",
        wrong_reason_b: "金曜日の午後に会うという予定は会話に示されていません。",
        wrong_reason_c: "次の月曜日に会うという合意は会話に含まれていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_c",
    set_number: 1,
    audio_url: audio_url,
    questions: [
      {
        tag: "talk",
        question_text: "What is the lecture mainly about?",
        question_audio_url: audio_url,
        choice_a: "The history of the printing press.",
        choice_b: "How the internet changed communication.",
        choice_c: "The development of written language.",
        choice_d: "Modern journalism techniques.",
        correct_choice: "C",
        explanation: "文字言語の発展について概説しています。",
        wrong_reason_a: "印刷機の歴史はトークのテーマではありません。",
        wrong_reason_b: "インターネットが通信を変えた話は講義の主題に含まれていません。",
        wrong_reason_d: "現代のジャーナリズム技術はトークのテーマではありません。"
      },
      {
        tag: "talk",
        question_text: "According to the speaker, what was significant about cuneiform?",
        question_audio_url: audio_url,
        choice_a: "It was used only by rulers.",
        choice_b: "It was one of the earliest writing systems.",
        choice_c: "It was invented in Egypt.",
        choice_d: "It used an alphabetic system.",
        correct_choice: "B",
        explanation: "楔形文字は最古の文字体系のひとつとして重要です。",
        wrong_reason_a: "楔形文字が支配者だけに使われたという内容は述べられていません。",
        wrong_reason_c: "楔形文字はエジプトではなくメソポタミアで発明されました。",
        wrong_reason_d: "楔形文字はアルファベット体系を使っておらず、表意・音節文字です。"
      },
      {
        tag: "talk",
        question_text: "What will the professor likely discuss next?",
        question_audio_url: audio_url,
        choice_a: "The spread of literacy in Europe.",
        choice_b: "Modern digital writing tools.",
        choice_c: "The alphabet's origin.",
        choice_d: "Ancient oral traditions.",
        correct_choice: "C",
        explanation: "アルファベットの起源に話題が移ると示唆されています。",
        wrong_reason_a: "ヨーロッパにおける識字率の普及については次のテーマとして示されていません。",
        wrong_reason_b: "現代のデジタルライティングツールは古代文字の講義に続く話題として示唆されていません。",
        wrong_reason_d: "古代の口承伝統は次の話題として講義中で示されていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_c",
    set_number: 2,
    audio_url: audio_url,
    questions: [
      {
        tag: "talk",
        question_text: "What is the main point of the talk?",
        question_audio_url: audio_url,
        choice_a: "How to reduce plastic waste on campus.",
        choice_b: "The importance of recycling programs.",
        choice_c: "New environmental policies at the university.",
        choice_d: "The effects of climate change on local weather.",
        correct_choice: "A",
        explanation: "キャンパス内のプラスチックごみ削減が主題です。",
        wrong_reason_b: "リサイクルプログラムの重要性はトークの主旨ではなく、手段の一つとして触れられる程度です。",
        wrong_reason_c: "大学の新しい環境方針はトークの中心テーマとして明示されていません。",
        wrong_reason_d: "気候変動が地域の天候に与える影響はトークのテーマではありません。"
      },
      {
        tag: "talk",
        question_text: "What action does the speaker encourage students to take?",
        question_audio_url: audio_url,
        choice_a: "Bring reusable containers to the dining hall.",
        choice_b: "Attend an upcoming environmental workshop.",
        choice_c: "Sign a petition for solar panels.",
        choice_d: "Volunteer for a campus clean-up event.",
        correct_choice: "A",
        explanation: "再利用可能な容器を食堂に持参することを促しています。",
        wrong_reason_b: "環境ワークショップへの参加を促す発言はトーク中にありません。",
        wrong_reason_c: "太陽光パネルの請願書への署名を求める内容はトークに含まれていません。",
        wrong_reason_d: "キャンパスの清掃活動へのボランティア参加はトークで呼びかけられていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "structure",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        tag: "sentenceStruct",
        question_text: "Neither the students nor the teacher ------- aware of the schedule change.",
        choice_a: "were",
        choice_b: "was",
        choice_c: "are",
        choice_d: "have been",
        correct_choice: "B",
        explanation: "Neither A nor B の場合、動詞はBに一致します。teacher が単数なので was。",
        wrong_reason_a: "were は複数形で、直近の主語 teacher（単数）に一致しません。",
        wrong_reason_c: "are は現在形ですが、文脈は過去の出来事を指しており時制が合いません。",
        wrong_reason_d: "have been は現在完了形で、過去の特定の出来事を述べるこの文には合いません。"
      },
      {
        tag: "verbForm",
        question_text: "The committee ------- a decision by the end of the week.",
        choice_a: "will have reached",
        choice_b: "reach",
        choice_c: "has reached",
        choice_d: "reaching",
        correct_choice: "A",
        explanation: "by the end of the week という期限があるため未来完了形が適切です。",
        wrong_reason_b: "reach は単純現在形で、未来の期限を持つ文には合いません。",
        wrong_reason_c: "has reached は現在完了形で、未来の期限「週末まで」と矛盾します。",
        wrong_reason_d: "reaching は動名詞・現在分詞で、述語動詞として使えません。"
      },
      {
        tag: "sentenceStruct",
        question_text: "Rarely ------- such a talented musician in this small town.",
        choice_a: "we have seen",
        choice_b: "have we seen",
        choice_c: "we had seen",
        choice_d: "did we see",
        correct_choice: "B",
        explanation: "否定副詞 Rarely が文頭に来ると倒置が起きます。",
        wrong_reason_a: "倒置が起きていないため文法的に誤りです。Rarely が文頭の場合、助動詞が主語の前に来なければなりません。",
        wrong_reason_c: "倒置が起きておらず、かつ過去完了形は文脈に合いません。",
        wrong_reason_d: "did を使った倒置は可能ですが、現在完了の文脈（これまでに見たことがない）には have を使った倒置が適切です。"
      },
      {
        tag: "verbForm",
        question_text: "The results of the experiment ------- published in a scientific journal.",
        choice_a: "was",
        choice_b: "were",
        choice_c: "is",
        choice_d: "has been",
        correct_choice: "B",
        explanation: "results は複数形なので were が正しいです。",
        wrong_reason_a: "was は単数形で、主語 results（複数）に一致しません。",
        wrong_reason_c: "is は単数・現在形で、複数の主語かつ過去の文脈に合いません。",
        wrong_reason_d: "has been は単数の現在完了形で、複数の主語 results には使えません。"
      },
      {
        tag: "verbForm",
        question_text: "By the time she arrived, the meeting -------.",
        choice_a: "already ended",
        choice_b: "has already ended",
        choice_c: "had already ended",
        choice_d: "will already end",
        correct_choice: "C",
        explanation: "過去のある時点より前に完了していた出来事には過去完了形を使います。",
        wrong_reason_a: "already ended は単純過去形で、「到着した時点」より前に完了していたことを表すには不十分です。",
        wrong_reason_b: "has already ended は現在完了形で、過去の基準時点より前の出来事を表せません。",
        wrong_reason_d: "will already end は未来形で、過去の文脈に全く合いません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "structure",
    part_type: "part_b",
    set_number: 1,
    questions: [
      {
        tag: "verbForm",
        question_text: "The (A) amount of (B) students enrolling in online courses (C) have (D) increased significantly.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "C",
        explanation: "amount of ではなく number of を使う場合は複数扱いですが、amount は不可算名詞と共に使うため、正しくは number of students → has increased となるべきです。ここでは have → has が誤りです。",
        wrong_reason_a: "amount of は不可算名詞に使うのが本来の用法ですが、ここでは誤りの場所ではありません。",
        wrong_reason_b: "students という名詞自体の使い方は文中で問題ありません。",
        wrong_reason_d: "increased は動詞の過去分詞として正しく使われています。"
      },
      {
        tag: "modifierConnect",
        question_text: "(A) Despite of (B) the heavy rain, the outdoor concert (C) continued (D) as planned.",
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
        question_text: "The scientist (A) which (B) discovered the vaccine (C) was awarded (D) the Nobel Prize.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "人を指す関係代名詞は which ではなく who を使います。",
        wrong_reason_b: "discovered は関係節内の動詞として文法的に正しいです。",
        wrong_reason_c: "was awarded は受動態として正しく使われています。",
        wrong_reason_d: "the Nobel Prize は was awarded の目的語として正しいです。"
      },
      {
        tag: "modifierConnect",
        question_text: "She (A) has been working (B) on the project (C) since (D) three months.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "C",
        explanation: "期間を表す場合は since ではなく for を使います。",
        wrong_reason_a: "has been working は現在完了進行形として正しい形です。",
        wrong_reason_b: "on the project は正しい前置詞句です。",
        wrong_reason_d: "three months という期間の表現自体は問題ありません。誤りは前置詞 since にあります。"
      },
      {
        tag: "verbForm",
        question_text: "The manager (A) asked the employees (B) to completed (C) the report (D) before noon.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "B",
        explanation: "asked to の後は原形���定詞が必要です。to completed → to complete が正しいです。",
        wrong_reason_a: "asked は過去形の動詞として正しく使われています。",
        wrong_reason_c: "the report は complete の目的語として正しいです。",
        wrong_reason_d: "before noon は時間の前置詞句として文法的に問題ありません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "reading",
    part_type: "passages",
    set_number: 1,
    passage: <<~TEXT,
      The ocean covers more than 70 percent of Earth's surface and plays a crucial role in regulating the planet's climate. Without the ocean, life as we know it would not exist. It absorbs a significant portion of the solar energy that reaches Earth and redistributes that heat through a global system of currents known as thermohaline circulation. This process helps stabilize temperatures across continents, keeping coastal regions warmer in winter and cooler in summer than they would otherwise be.

      Ocean currents also distribute heat around the globe, influencing weather patterns and making many regions habitable. For example, the Gulf Stream carries warm water from the Gulf of Mexico northward along the eastern coast of North America and across the Atlantic to Western Europe, giving countries like the United Kingdom a much milder climate than their latitude would otherwise suggest. Disruptions to such currents, potentially caused by climate change, could have far-reaching consequences for global weather systems.

      Beyond climate regulation, the ocean supports an extraordinary diversity of life, from microscopic phytoplankton to the blue whale, the largest animal on Earth. Coral reefs, often called the "rainforests of the sea," provide habitat for roughly 25 percent of all marine species despite covering less than one percent of the ocean floor. Despite its importance, much of the deep ocean remains unexplored due to the extreme pressures and darkness found at great depths. Scientists estimate that more than 80 percent of the ocean has never been mapped or directly observed, suggesting that many species and geological features have yet to be discovered.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "What percentage of Earth's surface does the ocean cover?",
        choice_a: "More than 50 percent.",
        choice_b: "Exactly 70 percent.",
        choice_c: "More than 70 percent.",
        choice_d: "Less than 60 percent.",
        correct_choice: "C",
        explanation: "本文に「more than 70 percent」と明記されています。",
        wrong_reason_a: "50パーセント以上という記述は本文にありません。正確な表現は「more than 70 percent」です。",
        wrong_reason_b: "「ちょうど70パーセント」とは書かれておらず、「70パーセント以上」が正しい記述です。",
        wrong_reason_d: "60パーセント未満という情報は本文に含まれておらず、実際の数値と大きく異なります。"
      },
      {
        tag: "fact",
        question_text: "According to the passage, what do ocean currents do?",
        choice_a: "Create earthquakes.",
        choice_b: "Distribute heat around the globe.",
        choice_c: "Cause extreme weather events.",
        choice_d: "Provide fresh water to coastlines.",
        correct_choice: "B",
        explanation: "海流が地球全体に熱を分配すると説明されています。",
        wrong_reason_a: "海流が地震を引き起こすという内容は本文に一切記載されていません。",
        wrong_reason_c: "極端な気象現象を引き起こすとは本文には書かれていません（気候変動による影響の可能性は触れられていますが）。",
        wrong_reason_d: "海流が海岸線に淡水を供給するという記述は本文にありません。"
      },
      {
        tag: "fact",
        question_text: "Why does much of the deep ocean remain unexplored?",
        choice_a: "It is too expensive to study.",
        choice_b: "Scientists are not interested in it.",
        choice_c: "It is protected by international law.",
        choice_d: "Extreme pressures and darkness make exploration difficult.",
        correct_choice: "D",
        explanation: "極端な圧力と暗さが探索を困難にしていると述べられています。",
        wrong_reason_a: "費用が高すぎるという理由は本文中に示されていません。",
        wrong_reason_b: "科学者が興味を持っていないとは本文に書かれておらず、実際には逆の内容が示唆されています。",
        wrong_reason_c: "国際法で保護されているという理由は本文中に全く記載されていません。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "reading",
    part_type: "passages",
    set_number: 2,
    passage: <<~TEXT,
      The Renaissance, which began in Italy during the 14th century, marked a profound transformation in European art, science, and philosophy. The word "Renaissance" comes from the French term meaning "rebirth," reflecting the era's emphasis on reviving the intellectual and cultural achievements of ancient Greece and Rome. This movement gradually spread from the Italian city-states — such as Florence, Venice, and Rome — northward into France, Germany, England, and the rest of Europe over the following two centuries.

      Scholars rediscovered ancient Greek and Roman texts, which inspired new ways of thinking about the human experience. This intellectual shift, known as humanism, placed greater emphasis on the individual, critical reasoning, and the value of earthly life rather than solely focusing on religious doctrine. Humanist thinkers such as Erasmus and Petrarch encouraged education based on classical literature, rhetoric, and moral philosophy, laying the groundwork for modern academic traditions.

      In the visual arts, a commitment to realism and the study of anatomy transformed the way artists portrayed the human body. Artists such as Leonardo da Vinci and Michelangelo produced works that celebrated both human beauty and intellectual achievement. Leonardo's meticulous notebooks blended art with scientific observation, while Michelangelo's sculptures and frescoes conveyed emotional depth and physical power that had rarely been seen before. The development of linear perspective by architects and painters such as Brunelleschi and Alberti gave artworks a convincing sense of three-dimensional space, fundamentally changing European visual culture.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "Where did the Renaissance begin?",
        choice_a: "France.",
        choice_b: "Italy.",
        choice_c: "Greece.",
        choice_d: "England.",
        correct_choice: "B",
        explanation: "本文冒頭に「began in Italy」と明記されています。",
        wrong_reason_a: "フランスにはルネサンスが広まりましたが、発祥の地ではありません。",
        wrong_reason_c: "ギリシャはルネサンスが復興しようとした古典文化の源ですが、運動の発祥地ではありません。",
        wrong_reason_d: "イングランドにもルネサンスは広まりましたが、始まりの地ではありません。"
      },
      {
        tag: "fact",
        question_text: "What inspired new ways of thinking during the Renaissance?",
        choice_a: "Religious reforms.",
        choice_b: "Industrial inventions.",
        choice_c: "Rediscovered ancient Greek and Roman texts.",
        choice_d: "Trade with Asia.",
        correct_choice: "C",
        explanation: "古代ギリシャ・ローマのテキストの再発見が新思想を促しました。",
        wrong_reason_a: "宗教改革はルネサンスと同時期の動きですが、新しい思考の直接の触発源として本文に示されていません。",
        wrong_reason_b: "産業的発明はルネサンスの文脈で本文中に言及されていません。",
        wrong_reason_d: "アジアとの貿易は本文で新思想の源として示されていません。"
      },
      {
        tag: "inference",
        question_text: "Which of the following best describes the Renaissance?",
        choice_a: "A period of political revolution.",
        choice_b: "A transformation in art, science, and philosophy.",
        choice_c: "A religious movement against the Church.",
        choice_d: "A period of economic decline.",
        correct_choice: "B",
        explanation: "芸術・科学・哲学の深い変革と本文で説明されています。",
        wrong_reason_a: "政治革命については本文で主要なテーマとして示されていません。",
        wrong_reason_c: "教会への反発を目的とした宗教運動とは本文に描かれていません。ヒューマニズムは宗教を否定したわけではありません。",
        wrong_reason_d: "経済的衰退はルネサンスの特徴として本文に示されておらず、むしろ都市国家の隆盛が示されています。"
      }
    ]
  )

  create_mock_set!(
    mock: mock2,
    section_type: "reading",
    part_type: "passages",
    set_number: 3,
    passage: <<~TEXT,
      Sleep is essential for maintaining both physical and mental health, yet it is one of the most commonly neglected aspects of modern life. In many cultures, long working hours and constant connectivity through digital devices have contributed to widespread sleep deprivation. While individuals may adapt to reduced sleep over time, research consistently shows that the body and brain suffer significant consequences when deprived of adequate rest.

      During sleep, the body carries out a range of vital restorative processes. It repairs damaged tissues, consolidates memories formed during the day, and releases hormones that support growth and immune function. The brain, in particular, uses sleep to clear metabolic waste products that accumulate during waking hours. Scientists believe this cleaning process, driven by the glymphatic system, may play a role in reducing the risk of neurodegenerative diseases such as Alzheimer's.

      Research suggests that adults need between seven and nine hours of sleep per night to function optimally, though individual needs vary based on age, genetics, and lifestyle. Children and teenagers require considerably more sleep to support their developing brains and bodies. Chronic sleep deprivation has been linked to a range of serious health problems, including obesity, type 2 diabetes, cardiovascular disease, and weakened immunity. Mental health is also affected; insufficient sleep is associated with increased risk of anxiety, depression, and impaired emotional regulation. Despite this evidence, many people continue to view sleep as a luxury rather than a biological necessity.
    TEXT
    questions: [
      {
        tag: "fact",
        question_text: "What is one thing the body does during sleep?",
        choice_a: "Increases blood pressure.",
        choice_b: "Repairs tissues.",
        choice_c: "Reduces hormone production.",
        choice_d: "Burns more calories.",
        correct_choice: "B",
        explanation: "「repairs tissues」と本文に明記されています。",
        wrong_reason_a: "睡眠中に血圧が上昇するとは本文に書かれていません。",
        wrong_reason_c: "ホルモン分泌が減少するとは書かれておらず、むしろ成長・免疫を支えるホルモンを放出すると述べられています。",
        wrong_reason_d: "睡眠中のカロリー消費については本文中に言及がありません。"
      },
      {
        tag: "fact",
        question_text: "How many hours of sleep do adults need per night?",
        choice_a: "Five to seven hours.",
        choice_b: "Six to eight hours.",
        choice_c: "Seven to nine hours.",
        choice_d: "Eight to ten hours.",
        correct_choice: "C",
        explanation: "本文に「between seven and nine hours」と記載されています。",
        wrong_reason_a: "5〜7時間という数値は本文に示されておらず、推奨より少ない睡眠時間です。",
        wrong_reason_b: "6〜8時間という記述は本文にありません。正しくは7〜9時間です。",
        wrong_reason_d: "8〜10時間という数値は本文に記載されておらず、推奨より多い範囲です。"
      },
      {
        tag: "vocab",
        question_text: "What does the word 'chronic' most nearly mean?",
        choice_a: "Temporary.",
        choice_b: "Severe.",
        choice_c: "Persistent.",
        choice_d: "Occasional.",
        correct_choice: "C",
        explanation: "chronic は「慢性的な・持続的な」という意味です。",
        wrong_reason_a: "temporary は「一時的な」という意味で、chronic（慢性的な）の反意語に近いです。",
        wrong_reason_b: "severe は「深刻な・重度の」という意味で、chronic の本来の意味とは異なります。",
        wrong_reason_d: "occasional は「時折の」という意味で、chronic の意味と正反対です。"
      }
    ]
  )

  puts "Seed finished."
end

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

  PART_DISPLAY_ORDERS = {
    "part_a" => 1,
    "part_b" => 2,
    "part_c" => 3,
    "passages" => 1
  }.freeze

  def create_exercise_set!(section_type:, part_type:, set_number:, passage: nil, audio_url: nil, questions:)
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
      audio_url: audio_url
    )

    questions.each_with_index do |question_data, index|
      question_set.questions.create!(
        display_order: index + 1,
        question_text: question_data.fetch(:question_text),
        audio_url: question_data[:audio_url],
        choice_a: question_data.fetch(:choice_a),
        choice_b: question_data.fetch(:choice_b),
        choice_c: question_data.fetch(:choice_c),
        choice_d: question_data.fetch(:choice_d),
        correct_choice: question_data.fetch(:correct_choice),
        explanation: question_data[:explanation]
      )
    end

    exercise
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

  demo_user = User.find_or_initialize_by(email: "demo@example.com")
  demo_user.username = "デモユーザー"
  demo_user.password = "password"
  demo_user.password_confirmation = "password"
  demo_user.terms_agreed = true
  demo_user.confirmed_at ||= Time.current
  demo_user.save!

  test_user = User.find_or_initialize_by(email: "test@gmail.com")
  test_user.username = "テストユーザー"
  test_user.password = "testuser1234"
  test_user.password_confirmation = "testuser1234"
  test_user.terms_agreed = true
  test_user.confirmed_at ||= Time.current
  test_user.save!

  audio_url = "https://preness-listening-audio.s3.ap-northeast-1.amazonaws.com/PartB_02.wav"

  create_exercise_set!(
    section_type: "listening",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        question_text: "What does the woman imply?",
        audio_url: audio_url,
        choice_a: "She will return the book today.",
        choice_b: "The book may be kept at the front desk.",
        choice_c: "The library is closed for research.",
        choice_d: "She has the book in her dorm room.",
        correct_choice: "B",
        explanation: "“on reserve” は特定の場所で保管されている可能性を示唆します。"
      },
      {
        question_text: "What will the man probably do next?",
        audio_url: audio_url,
        choice_a: "Ask at the front desk.",
        choice_b: "Go to the dormitory.",
        choice_c: "Buy the book online.",
        choice_d: "Cancel his research plan.",
        correct_choice: "A",
        explanation: "女性の示唆から、フロントデスクで確認するのが自然です。"
      },
      {
        question_text: "Where does the conversation most likely take place?",
        audio_url: audio_url,
        choice_a: "At a café.",
        choice_b: "In a classroom.",
        choice_c: "At a library.",
        choice_d: "At a bookstore.",
        correct_choice: "C",
        explanation: "予約本やフロントデスクの話題から図書館が想定されます。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "listening",
    part_type: "part_a",
    set_number: 2,
    questions: [
      {
        question_text: "What is the man concerned about?",
        audio_url: audio_url,
        choice_a: "Missing the deadline.",
        choice_b: "Forgetting his umbrella.",
        choice_c: "Losing his student ID.",
        choice_d: "Getting a lower grade.",
        correct_choice: "A",
        explanation: "期限に間に合うかどうかを気にしています。"
      },
      {
        question_text: "What does the woman suggest?",
        audio_url: audio_url,
        choice_a: "Submitting online.",
        choice_b: "Waiting until tomorrow.",
        choice_c: "Asking for a refund.",
        choice_d: "Changing the course.",
        correct_choice: "A",
        explanation: "オンライン提出が可能だと示しています。"
      },
      {
        question_text: "What will they do later?",
        audio_url: audio_url,
        choice_a: "Meet at the library.",
        choice_b: "Go to the gym.",
        choice_c: "Visit the museum.",
        choice_d: "Take a taxi.",
        correct_choice: "A",
        explanation: "後で図書館で会う流れです。"
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
        question_text: "What are the students mainly discussing?",
        audio_url: audio_url,
        choice_a: "Weekend plans.",
        choice_b: "A research project.",
        choice_c: "A scholarship requirement.",
        choice_d: "How to start a club.",
        correct_choice: "B",
        explanation: "会話の中心は授業のプロジェクトです。"
      },
      {
        question_text: "What does the woman offer to do?",
        audio_url: audio_url,
        choice_a: "Collect the data.",
        choice_b: "Write the introduction.",
        choice_c: "Make the slides.",
        choice_d: "Present alone.",
        correct_choice: "C",
        explanation: "発表用のスライド作成を引き受けています。"
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
        question_text: "What is the purpose of the talk?",
        audio_url: audio_url,
        choice_a: "To introduce the library services.",
        choice_b: "To explain campus history.",
        choice_c: "To describe a new major.",
        choice_d: "To announce new graduation rules.",
        correct_choice: "A",
        explanation: "図書館の使い方を案内しています。"
      },
      {
        question_text: "What does the speaker recommend?",
        audio_url: audio_url,
        choice_a: "Borrowing only one book at a time.",
        choice_b: "Using the online catalog.",
        choice_c: "Avoiding group study rooms.",
        choice_d: "Buying textbooks immediately.",
        correct_choice: "B",
        explanation: "オンラインカタログの利用が推奨されています。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "structure",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        question_text: "The Eiffel Tower ------- in 1889 for the World's Fair.",
        choice_a: "was built",
        choice_b: "building",
        choice_c: "built",
        choice_d: "to build",
        correct_choice: "A",
        explanation: "受動態が必要です。"
      },
      {
        question_text: "If I ------- more time, I would travel more often.",
        choice_a: "have",
        choice_b: "had",
        choice_c: "will have",
        choice_d: "am having",
        correct_choice: "B",
        explanation: "仮定法過去の形です。"
      },
      {
        question_text: "The report must ------- by Friday.",
        choice_a: "submit",
        choice_b: "submitted",
        choice_c: "be submitted",
        choice_d: "submitting",
        correct_choice: "C",
        explanation: "must + be + 過去分詞。"
      }
    ]
  )

  create_exercise_set!(
    section_type: "structure",
    part_type: "part_b",
    set_number: 1,
    questions: [
      {
        question_text: "The (A) beautifully flowers (B) in the garden (C) are blooming (D) now.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "beautifully → beautiful が適切です。"
      },
      {
        question_text: "She (A) suggested me (B) to take (C) a short break (D).",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "B",
        explanation: "suggested me → suggested that I / suggested taking の形。"
      },
      {
        question_text: "I (A) have lived (B) here (C) since five years (D).",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "D",
        explanation: "since five years → for five years。"
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
        question_text: "What is the main topic of the passage?",
        choice_a: "The history of vacuum tubes.",
        choice_b: "The speed and impact of modern computers.",
        choice_c: "How to repair a broken computer.",
        choice_d: "The cost of manufacturing microchips.",
        correct_choice: "B",
        explanation: "コンピュータの高速化と影響について述べています。"
      },
      {
        question_text: "Which fields are mentioned as being affected?",
        choice_a: "Science, engineering, finance.",
        choice_b: "Art, music, sports.",
        choice_c: "Cooking, farming, fishing.",
        choice_d: "Travel, fashion, design.",
        correct_choice: "A",
        explanation: "本文に明記されています。"
      },
      {
        question_text: "What does 'remarkable' most nearly mean?",
        choice_a: "Ordinary",
        choice_b: "Notable",
        choice_c: "Unsafe",
        choice_d: "Slow",
        correct_choice: "B",
        explanation: "remarkable は「注目すべき」の意味です。"
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
        question_text: "What does the passage suggest about study routines?",
        choice_a: "They do not affect retention.",
        choice_b: "Long sessions are always best.",
        choice_c: "Regular routines can improve retention.",
        choice_d: "Studying should be avoided.",
        correct_choice: "C",
        explanation: "定期的な学習が定着に役立つと述べています。"
      },
      {
        question_text: "What kind of sessions are recommended?",
        choice_a: "Short and consistent",
        choice_b: "Only long sessions",
        choice_c: "Only weekend sessions",
        choice_d: "Late-night sessions",
        correct_choice: "A",
        explanation: "短く継続的な学習が良いと説明しています。"
      },
      {
        question_text: "Which is contrasted in the passage?",
        choice_a: "Morning vs night",
        choice_b: "Short consistent vs infrequent long",
        choice_c: "Reading vs listening",
        choice_d: "Online vs offline",
        correct_choice: "B",
        explanation: "短く継続 vs 長く不定期 の対比です。"
      }
    ]
  )

  puts "Seed finished."
end

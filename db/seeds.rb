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

  def create_mock_set!(mock:, section_type:, part_type:, set_number:, passage: nil, audio_url: nil, questions:)
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

  # --- Fillers to reach 10 sets for each part ---

  # Listening Part A (3-10)
  (3..10).each do |i|
    create_exercise_set!(
      section_type: "listening",
      part_type: "part_a",
      set_number: i,
      questions: 3.times.map { |j|
        {
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

  create_mock_set!(
    mock: mock1,
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

  create_mock_set!(
    mock: mock1,
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

  create_mock_set!(
    mock: mock1,
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

  mock2 = Mock.create!(title: "第2回 模擬試験")

  create_mock_set!(
    mock: mock2,
    section_type: "listening",
    part_type: "part_a",
    set_number: 1,
    questions: [
      {
        question_text: "What does the man suggest the woman do?",
        audio_url: audio_url,
        choice_a: "Apply for a scholarship.",
        choice_b: "Talk to the professor directly.",
        choice_c: "Drop the course.",
        choice_d: "Visit the tutoring center.",
        correct_choice: "D",
        explanation: "男性はチュータリングセンターの利用を勧めています。"
      },
      {
        question_text: "What is the woman's problem?",
        audio_url: audio_url,
        choice_a: "She lost her textbook.",
        choice_b: "She missed the midterm.",
        choice_c: "She is struggling with chemistry.",
        choice_d: "She cannot register for classes.",
        correct_choice: "C",
        explanation: "化学の授業に苦労していることが会話から分かります。"
      },
      {
        question_text: "What will the woman probably do next?",
        audio_url: audio_url,
        choice_a: "Go to the library.",
        choice_b: "Call her parents.",
        choice_c: "Visit the tutoring center.",
        choice_d: "Study alone in her room.",
        correct_choice: "C",
        explanation: "男性の提案を受け入れてチュータリングセンターへ向かうと考えられます。"
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
        question_text: "What does the woman mean?",
        audio_url: audio_url,
        choice_a: "She is very hungry.",
        choice_b: "The cafeteria is not open yet.",
        choice_c: "She would rather not eat at the cafeteria.",
        choice_d: "The food at the cafeteria is expensive.",
        correct_choice: "C",
        explanation: "発言から、カフェテリアへの否定的なニュアンスが読み取れます。"
      },
      {
        question_text: "What does the man suggest?",
        audio_url: audio_url,
        choice_a: "Trying a restaurant nearby.",
        choice_b: "Cooking at home.",
        choice_c: "Skipping lunch.",
        choice_d: "Ordering delivery.",
        correct_choice: "A",
        explanation: "近くのレストランを試すことを提案しています。"
      },
      {
        question_text: "How does the woman feel at the end?",
        audio_url: audio_url,
        choice_a: "Disappointed.",
        choice_b: "Uncertain.",
        choice_c: "Agreeable.",
        choice_d: "Frustrated.",
        correct_choice: "C",
        explanation: "会話の最後で女性は提案に同意しています。"
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
        question_text: "What does the professor imply?",
        audio_url: audio_url,
        choice_a: "The assignment is due today.",
        choice_b: "Students should start early.",
        choice_c: "The exam has been cancelled.",
        choice_d: "Extra credit is not available.",
        correct_choice: "B",
        explanation: "早めに始めるべきだという示唆が含まれています。"
      },
      {
        question_text: "What is the student's concern?",
        audio_url: audio_url,
        choice_a: "Finding a study partner.",
        choice_b: "Understanding the assignment topic.",
        choice_c: "Meeting the word count requirement.",
        choice_d: "Accessing the online library.",
        correct_choice: "B",
        explanation: "課題のトピックについて理解できていないことを心配しています。"
      },
      {
        question_text: "What does the professor offer?",
        audio_url: audio_url,
        choice_a: "To extend the deadline.",
        choice_b: "To provide a sample paper.",
        choice_c: "To hold office hours tomorrow.",
        choice_d: "To assign a different topic.",
        correct_choice: "C",
        explanation: "翌日のオフィスアワーを設けると申し出ています。"
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
        question_text: "What is the main topic of the conversation?",
        audio_url: audio_url,
        choice_a: "Planning a campus event.",
        choice_b: "Choosing a major.",
        choice_c: "Applying for graduate school.",
        choice_d: "Registering for next semester's classes.",
        correct_choice: "D",
        explanation: "来学期の履修登録について話し合っています。"
      },
      {
        question_text: "What problem does the man mention?",
        audio_url: audio_url,
        choice_a: "A class he wants is already full.",
        choice_b: "He forgot his student ID.",
        choice_c: "His advisor is unavailable.",
        choice_d: "The online portal is down.",
        correct_choice: "A",
        explanation: "希望するクラスが満員であることを問題として挙げています。"
      },
      {
        question_text: "What does the woman recommend?",
        audio_url: audio_url,
        choice_a: "Contacting the registrar's office.",
        choice_b: "Joining the waitlist.",
        choice_c: "Taking an equivalent online course.",
        choice_d: "Asking the professor for permission.",
        correct_choice: "B",
        explanation: "ウェイティングリストに登録することを勧めています。"
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
        question_text: "What are the speakers preparing for?",
        audio_url: audio_url,
        choice_a: "A science fair.",
        choice_b: "A group presentation.",
        choice_c: "A study abroad application.",
        choice_d: "A campus orientation.",
        correct_choice: "B",
        explanation: "グループ発表の準備について話し合っています。"
      },
      {
        question_text: "Who will handle the data analysis?",
        audio_url: audio_url,
        choice_a: "The woman.",
        choice_b: "Both of them together.",
        choice_c: "The man.",
        choice_d: "A third group member.",
        correct_choice: "C",
        explanation: "男性がデータ分析を担当することになりました。"
      },
      {
        question_text: "When will they meet again?",
        audio_url: audio_url,
        choice_a: "Tomorrow morning.",
        choice_b: "Friday afternoon.",
        choice_c: "Next Monday.",
        choice_d: "Over the weekend.",
        correct_choice: "D",
        explanation: "週末に再び集まることで合意しています。"
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
        question_text: "What is the lecture mainly about?",
        audio_url: audio_url,
        choice_a: "The history of the printing press.",
        choice_b: "How the internet changed communication.",
        choice_c: "The development of written language.",
        choice_d: "Modern journalism techniques.",
        correct_choice: "C",
        explanation: "文字言語の発展について概説しています。"
      },
      {
        question_text: "According to the speaker, what was significant about cuneiform?",
        audio_url: audio_url,
        choice_a: "It was used only by rulers.",
        choice_b: "It was one of the earliest writing systems.",
        choice_c: "It was invented in Egypt.",
        choice_d: "It used an alphabetic system.",
        correct_choice: "B",
        explanation: "楔形文字は最古の文字体系のひとつとして重要です。"
      },
      {
        question_text: "What will the professor likely discuss next?",
        audio_url: audio_url,
        choice_a: "The spread of literacy in Europe.",
        choice_b: "Modern digital writing tools.",
        choice_c: "The alphabet's origin.",
        choice_d: "Ancient oral traditions.",
        correct_choice: "C",
        explanation: "アルファベットの起源に話題が移ると示唆されています。"
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
        question_text: "What is the main point of the talk?",
        audio_url: audio_url,
        choice_a: "How to reduce plastic waste on campus.",
        choice_b: "The importance of recycling programs.",
        choice_c: "New environmental policies at the university.",
        choice_d: "The effects of climate change on local weather.",
        correct_choice: "A",
        explanation: "キャンパス内のプラスチックごみ削減が主題です。"
      },
      {
        question_text: "What action does the speaker encourage students to take?",
        audio_url: audio_url,
        choice_a: "Bring reusable containers to the dining hall.",
        choice_b: "Attend an upcoming environmental workshop.",
        choice_c: "Sign a petition for solar panels.",
        choice_d: "Volunteer for a campus clean-up event.",
        correct_choice: "A",
        explanation: "再利用可能な容器を食堂に持参することを促しています。"
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
        question_text: "Neither the students nor the teacher ------- aware of the schedule change.",
        choice_a: "were",
        choice_b: "was",
        choice_c: "are",
        choice_d: "have been",
        correct_choice: "B",
        explanation: "Neither A nor B の場合、動詞はBに一致します。teacher が単数なので was。"
      },
      {
        question_text: "The committee ------- a decision by the end of the week.",
        choice_a: "will have reached",
        choice_b: "reach",
        choice_c: "has reached",
        choice_d: "reaching",
        correct_choice: "A",
        explanation: "by the end of the week という期限があるため未来完了形が適切です。"
      },
      {
        question_text: "Rarely ------- such a talented musician in this small town.",
        choice_a: "we have seen",
        choice_b: "have we seen",
        choice_c: "we had seen",
        choice_d: "did we see",
        correct_choice: "B",
        explanation: "否定副詞 Rarely が文頭に来ると倒置が起きます。"
      },
      {
        question_text: "The results of the experiment ------- published in a scientific journal.",
        choice_a: "was",
        choice_b: "were",
        choice_c: "is",
        choice_d: "has been",
        correct_choice: "B",
        explanation: "results は複数形なので were が正しいです。"
      },
      {
        question_text: "By the time she arrived, the meeting -------.",
        choice_a: "already ended",
        choice_b: "has already ended",
        choice_c: "had already ended",
        choice_d: "will already end",
        correct_choice: "C",
        explanation: "過去のある時点より前に完了していた出来事には過去完了形を使います。"
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
        question_text: "The (A) amount of (B) students enrolling in online courses (C) have (D) increased significantly.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "C",
        explanation: "amount of ではなく number of を使う場合は複数扱いですが、amount は不可算名詞と共に使うため、正しくは number of students → has increased となるべきです。ここでは have → has が誤りです。"
      },
      {
        question_text: "(A) Despite of (B) the heavy rain, the outdoor concert (C) continued (D) as planned.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "despite は前置詞で of は不要です。despite the heavy rain が正しい形です。"
      },
      {
        question_text: "The scientist (A) which (B) discovered the vaccine (C) was awarded (D) the Nobel Prize.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "A",
        explanation: "人を指す関係代名詞は which ではなく who を使います。"
      },
      {
        question_text: "She (A) has been working (B) on the project (C) since (D) three months.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "C",
        explanation: "期間を表す場合は since ではなく for を使います。"
      },
      {
        question_text: "The manager (A) asked the employees (B) to completed (C) the report (D) before noon.",
        choice_a: "A",
        choice_b: "B",
        choice_c: "C",
        choice_d: "D",
        correct_choice: "B",
        explanation: "asked to の後は原形不定詞が必要です。to completed → to complete が正しいです。"
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
        question_text: "What percentage of Earth's surface does the ocean cover?",
        choice_a: "More than 50 percent.",
        choice_b: "Exactly 70 percent.",
        choice_c: "More than 70 percent.",
        choice_d: "Less than 60 percent.",
        correct_choice: "C",
        explanation: "本文に「more than 70 percent」と明記されています。"
      },
      {
        question_text: "According to the passage, what do ocean currents do?",
        choice_a: "Create earthquakes.",
        choice_b: "Distribute heat around the globe.",
        choice_c: "Cause extreme weather events.",
        choice_d: "Provide fresh water to coastlines.",
        correct_choice: "B",
        explanation: "海流が地球全体に熱を分配すると説明されています。"
      },
      {
        question_text: "Why does much of the deep ocean remain unexplored?",
        choice_a: "It is too expensive to study.",
        choice_b: "Scientists are not interested in it.",
        choice_c: "It is protected by international law.",
        choice_d: "Extreme pressures and darkness make exploration difficult.",
        correct_choice: "D",
        explanation: "極端な圧力と暗さが探索を困難にしていると述べられています。"
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
        question_text: "Where did the Renaissance begin?",
        choice_a: "France.",
        choice_b: "Italy.",
        choice_c: "Greece.",
        choice_d: "England.",
        correct_choice: "B",
        explanation: "本文冒頭に「began in Italy」と明記されています。"
      },
      {
        question_text: "What inspired new ways of thinking during the Renaissance?",
        choice_a: "Religious reforms.",
        choice_b: "Industrial inventions.",
        choice_c: "Rediscovered ancient Greek and Roman texts.",
        choice_d: "Trade with Asia.",
        correct_choice: "C",
        explanation: "古代ギリシャ・ローマのテキストの再発見が新思想を促しました。"
      },
      {
        question_text: "Which of the following best describes the Renaissance?",
        choice_a: "A period of political revolution.",
        choice_b: "A transformation in art, science, and philosophy.",
        choice_c: "A religious movement against the Church.",
        choice_d: "A period of economic decline.",
        correct_choice: "B",
        explanation: "芸術・科学・哲学の深い変革と本文で説明されています。"
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
        question_text: "What is one thing the body does during sleep?",
        choice_a: "Increases blood pressure.",
        choice_b: "Repairs tissues.",
        choice_c: "Reduces hormone production.",
        choice_d: "Burns more calories.",
        correct_choice: "B",
        explanation: "「repairs tissues」と本文に明記されています。"
      },
      {
        question_text: "How many hours of sleep do adults need per night?",
        choice_a: "Five to seven hours.",
        choice_b: "Six to eight hours.",
        choice_c: "Seven to nine hours.",
        choice_d: "Eight to ten hours.",
        correct_choice: "C",
        explanation: "本文に「between seven and nine hours」と記載されています。"
      },
      {
        question_text: "What does the word 'chronic' most nearly mean?",
        choice_a: "Temporary.",
        choice_b: "Severe.",
        choice_c: "Persistent.",
        choice_d: "Occasional.",
        correct_choice: "C",
        explanation: "chronic は「慢性的な・持続的な」という意味です。"
      }
    ]
  )

  puts "Seed finished."
end

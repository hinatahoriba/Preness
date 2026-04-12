module Mocks
  # FastAPI に送信するペイロードを Attempt の回答データから組み立てるサービス
  class BuildAnalysisPayload
    LISTENING_PART_TOTALS = {
      "part_a" => 30,
      "part_b" => 8,
      "part_c" => 12
    }.freeze

    STRUCTURE_PART_TOTALS = {
      "part_a" => 15,
      "part_b" => 25
    }.freeze

    READING_QUESTIONS_PER_SET = 10
    READING_SET_COUNT = 5

    def self.call(attempt)
      new(attempt).call
    end

    def initialize(attempt)
      @attempt = attempt
      @mock    = attempt.mockable
      # question_id => Answer のマップ（全回答を1回のクエリで取得）
      @answers_map = attempt.answers
        .includes(:question)
        .index_by(&:question_id)
    end

    def call
      {
        goal: build_goal,
        parts_accuracy: build_parts_accuracy,
        tags: build_tags
      }
    end

    private

    # ── goal ────────────────────────────────────────────────────────────────

    def build_goal
      target_score = @attempt.user.user_profile&.itp_target_score
      { target_score: target_score }
    end

    # ── parts_accuracy ──────────────────────────────────────────────────────

    def build_parts_accuracy
      {
        listening: build_listening_accuracy,
        structure: build_structure_accuracy,
        reading:   build_reading_accuracy
      }
    end

    def build_listening_accuracy
      section = find_section("listening")
      return empty_listening if section.nil?

      {
        partA: part_stats(section, "part_a", LISTENING_PART_TOTALS["part_a"]),
        partB: part_stats(section, "part_b", LISTENING_PART_TOTALS["part_b"]),
        partC: part_stats(section, "part_c", LISTENING_PART_TOTALS["part_c"])
      }
    end

    def build_structure_accuracy
      section = find_section("structure")
      return empty_structure if section.nil?

      {
        partA: part_stats(section, "part_a", STRUCTURE_PART_TOTALS["part_a"]),
        partB: part_stats(section, "part_b", STRUCTURE_PART_TOTALS["part_b"])
      }
    end

    def build_reading_accuracy
      section = find_section("reading")
      return {} if section.nil?

      part = section.parts.find { |p| p.part_type == "passages" }
      return {} if part.nil?

      question_sets = part.question_sets.sort_by(&:display_order)

      question_sets.first(READING_SET_COUNT).each_with_index.to_h do |qs, idx|
        key = "Reading_%02d" % (idx + 1)
        questions = qs.questions
        correct   = questions.count { |q| correct_answer?(q) }

        [key, {
          passage_thema: qs.passage_thema.presence,
          correct:       correct,
          total:         READING_QUESTIONS_PER_SET
        }.compact]
      end
    end

    # ── tags ────────────────────────────────────────────────────────────────

    def build_tags
      # 全セクションの全 Question を収集し、tag ごとに集計
      all_questions = @mock.sections.flat_map do |section|
        section.parts.flat_map do |part|
          part.question_sets.flat_map(&:questions)
        end
      end

      tagged_questions = all_questions.select(&:tag)

      tagged_questions.group_by(&:tag).transform_values do |questions|
        correct = questions.count { |q| correct_answer?(q) }
        { correct: correct, total: questions.size }
      end
    end

    # ── helpers ─────────────────────────────────────────────────────────────

    def find_section(section_type)
      @mock.sections.find { |s| s.section_type == section_type }
    end

    def part_stats(section, part_type, total)
      part      = section.parts.find { |p| p.part_type == part_type }
      questions = part ? part.question_sets.flat_map(&:questions) : []
      correct   = questions.count { |q| correct_answer?(q) }
      { correct: correct, total: total }
    end

    def correct_answer?(question)
      @answers_map[question.id]&.is_correct == true
    end

    def empty_listening
      {
        partA: { correct: 0, total: LISTENING_PART_TOTALS["part_a"] },
        partB: { correct: 0, total: LISTENING_PART_TOTALS["part_b"] },
        partC: { correct: 0, total: LISTENING_PART_TOTALS["part_c"] }
      }
    end

    def empty_structure
      {
        partA: { correct: 0, total: STRUCTURE_PART_TOTALS["part_a"] },
        partB: { correct: 0, total: STRUCTURE_PART_TOTALS["part_b"] }
      }
    end
  end
end

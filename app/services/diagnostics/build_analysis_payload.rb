module Diagnostics
  class BuildAnalysisPayload
    TAGS = Question::TAGS.freeze

    def self.call(attempt)
      new(attempt).call
    end

    def initialize(attempt)
      @attempt    = attempt
      @diagnostic = attempt.mockable
      @answers_map = attempt.answers
        .includes(:question)
        .index_by(&:question_id)
    end

    def call
      {
        goal:           build_goal,
        parts_accuracy: build_parts_accuracy,
        tags:           build_tags
      }
    end

    private

    def build_goal
      target_score = @attempt.user.user_profile&.itp_target_score
      return nil if target_score.nil?

      { target_score: target_score }
    end

    def build_parts_accuracy
      {
        listening: build_listening_accuracy,
        structure: build_structure_accuracy,
        reading:   build_reading_accuracy
      }
    end

    def build_listening_accuracy
      section = find_section("listening")
      return empty_part_accuracy("listening") if section.nil?

      build_part_accuracy(section, "listening")
    end

    def build_structure_accuracy
      section = find_section("structure")

      ExamCatalog.part_totals("structure").each_with_object({}) do |(part_type, _), result|
        part      = section&.parts&.find { |p| p.part_type == part_type }
        questions = part ? part.question_sets.flat_map(&:questions) : []
        correct   = questions.count { |q| correct_answer?(q) }
        result[part_key(part_type)] = { correct: correct, total: questions.size }
      end
    end

    def build_reading_accuracy
      section = find_section("reading")
      part    = section&.parts&.find { |p| p.part_type == "passages" }
      sets    = part ? part.question_sets.sort_by(&:display_order) : []

      (1..ExamCatalog::READING_SET_COUNT).each_with_object({}) do |idx, result|
        key = "Reading_%02d" % idx
        qs  = sets[idx - 1]

        if qs
          questions = qs.questions
          correct   = questions.count { |q| correct_answer?(q) }
          result[key] = { passage_theme: qs.passage_theme.presence, correct: correct, total: questions.size }
        else
          result[key] = { passage_theme: nil, correct: 0, total: 0 }
        end
      end
    end

    def build_tags
      all_questions = @diagnostic.sections.flat_map do |section|
        section.parts.flat_map do |part|
          part.question_sets.flat_map(&:questions)
        end
      end

      stats = TAGS.each_with_object({}) do |tag, result|
        result[tag] = { correct: 0, total: 0 }
      end

      all_questions.select(&:tag).group_by(&:tag).each do |tag, questions|
        correct = questions.count { |q| correct_answer?(q) }
        stats[tag] = { correct: correct, total: questions.size }
      end

      stats
    end

    def find_section(section_type)
      @diagnostic.sections.find { |s| s.section_type == section_type }
    end

    def part_stats(section, part_type, total)
      part      = section.parts.find { |p| p.part_type == part_type }
      questions = part ? part.question_sets.flat_map(&:questions) : []
      correct   = questions.count { |q| correct_answer?(q) }
      { correct: correct, total: total }
    end

    def build_part_accuracy(section, section_type)
      ExamCatalog.diagnostic_part_totals(section_type).each_with_object({}) do |(part_type, total), result|
        result[part_key(part_type)] = part_stats(section, part_type, total)
      end
    end

    def correct_answer?(question)
      @answers_map[question.id]&.is_correct == true
    end

    def empty_part_accuracy(section_type)
      ExamCatalog.diagnostic_part_totals(section_type).each_with_object({}) do |(part_type, total), result|
        result[part_key(part_type)] = { correct: 0, total: total }
      end
    end

    def part_key(part_type)
      part_type.camelize(:lower).to_sym
    end
  end
end

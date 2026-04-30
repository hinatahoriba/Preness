module Exercises
  class HistoryPresenter
    def initialize(attempts:, total_questions:, section:, part:, question_set:)
      @attempts = attempts
      @total_questions = total_questions
      @section = section
      @part = part
      @question_set = question_set
    end

    def title
      ExamCatalog.set_title(
        section_type: @section.section_type,
        part_type: @part.part_type,
        set_number: @question_set.display_order
      )
    end

    def rows
      @attempts.each_with_index.map do |attempt, index|
        correct_count = attempt.answers.count(&:is_correct)
        score_percent = percentage(correct_count, @total_questions)

        {
          attempt: attempt,
          number_label: @attempts.size - index,
          correct_count: correct_count,
          total_questions: @total_questions,
          score_percent: score_percent,
          score_class: score_class_for(score_percent)
        }
      end
    end

    private

    def percentage(correct, total)
      return 0 if total.zero?

      ((correct.to_f / total) * 100).round(1)
    end

    def score_class_for(score_percent)
      return "text-emerald-500" if score_percent >= 80
      return "text-yellow-500" if score_percent >= 60

      "text-red-500"
    end
  end
end

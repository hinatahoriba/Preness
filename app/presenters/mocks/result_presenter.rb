module Mocks
  class ResultPresenter
    attr_reader :filter, :part_filter

    def initialize(section_results:, filter:, part_filter:)
      @section_results = section_results
      @filter = normalize_filter(filter)
      @part_filter = part_filter.presence || "all"
    end

    def total_percent
      percentage(total_correct, total_questions)
    end

    def total_correct
      @section_results.sum { |result| result[:correct_count] }
    end

    def total_questions
      @section_results.sum { |result| result[:total_count] }
    end

    def filtered_sections
      @filtered_sections ||= @section_results.filter_map do |result|
        next if filtered_out?(result)

        display_questions = filter_questions(result[:questions], result[:answers_by_question_id])
        next if display_questions.empty?

        result.merge(
          display_questions: display_questions,
          section_name: ExamCatalog.section_label(result[:section].section_type)
        )
      end
    end

    def has_display_questions?
      filtered_sections.any?
    end

    def table_rows
      row_number = 0

      filtered_sections.flat_map do |result|
        result[:display_questions].map do |question|
          row_number += 1
          review = ExamSessions::QuestionReviewPresenter.new(
            question: question,
            answer: result[:answers_by_question_id][question.id],
            section_type: result[:section].section_type
          )

          {
            number: row_number,
            section_name: result[:section_name],
            question: question,
            review: review
          }
        end
      end
    end

    private

    def normalize_filter(filter)
      filter.presence_in(%w[all correct wrong]) || "wrong"
    end

    def filtered_out?(result)
      part_filter != "all" && result[:section].section_type != part_filter
    end

    def filter_questions(questions, answers_by_question_id)
      case filter
      when "all"
        questions
      when "correct"
        questions.select { |question| answers_by_question_id[question.id]&.is_correct == true }
      else
        questions.select { |question| answers_by_question_id[question.id]&.is_correct != true }
      end
    end

    def percentage(correct, total)
      return 0 if total.zero?

      ((correct.to_f / total) * 100).round(1)
    end
  end
end

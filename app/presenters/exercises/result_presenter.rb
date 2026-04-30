module Exercises
  class ResultPresenter
    def initialize(correct_count:, total_count:, section:, part:, question_set:)
      @correct_count = correct_count
      @total_count = total_count
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

    def score_percent
      return 0 if @total_count.zero?

      ((@correct_count.to_f / @total_count) * 100).round(1)
    end
  end
end

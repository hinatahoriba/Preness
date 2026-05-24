module Exercises
  module Parts
    class ShowPresenter
      def initialize(exercises:, latest_attempt_by_exercise_id:, section_type:, part_type:)
        @exercises                    = exercises
        @latest_attempt_by_exercise_id = latest_attempt_by_exercise_id
        @section_type                 = section_type
        @part_type                    = part_type
      end

      def title
        section = ExamCatalog.section_label(@section_type)
        part    = ExamCatalog.part_label(@part_type)
        part.present? ? "#{section} #{part}" : section
      end

      def rows
        sorted_exercises.each_with_index.filter_map do |exercise, index|
          question_sets = exercise.sections.first&.parts&.first&.question_sets
          next if question_sets.blank?

          attempt       = @latest_attempt_by_exercise_id[exercise.id]
          total_count   = question_sets.sum { |question_set| question_set.questions.size }
          correct_count = attempt ? attempt.answers.count(&:is_correct) : nil
          score_percent = correct_count ? ((correct_count.to_f / total_count) * 100).round(1) : nil

          {
            exercise:      exercise,
            set_number:    index + 1,
            attempted:     attempt.present?,
            attempt:       attempt,
            correct_count: correct_count,
            total_count:   total_count,
            score_percent: score_percent,
            score_color:   score_color_for(score_percent),
            bar_color:     bar_color_for(score_percent)
          }
        end
      end

      private

      def sorted_exercises
        @exercises.sort_by do |exercise|
          exercise.sections.first&.parts&.first&.question_sets&.first&.display_order || 0
        end
      end

      def score_color_for(score_percent)
        return nil unless score_percent

        if score_percent >= 80
          "text-teal-600"
        elsif score_percent >= 60
          "text-orange-500"
        else
          "text-red-600"
        end
      end

      def bar_color_for(score_percent)
        return nil unless score_percent

        if score_percent >= 80
          "bg-teal-600"
        elsif score_percent >= 60
          "bg-orange-500"
        else
          "bg-red-600"
        end
      end
    end
  end
end

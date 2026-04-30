module ExamSessions
  module Flow
    class Exercise
      Content = Struct.new(:section, :part, :question_set, :questions, keyword_init: true)
      Result = Struct.new(
        :attempt,
        :answers_by_question_id,
        :total_count,
        :correct_count,
        :answered_count,
        :filter,
        :display_questions,
        keyword_init: true
      )

      def initialize(exercise)
        @exercise = exercise
      end

      def content!
        section = @exercise.sections.first
        part = section&.parts&.first
        question_set = part&.question_sets&.first
        questions = question_set&.questions&.to_a || []

        raise ActiveRecord::RecordNotFound, "Exercise content is missing" if section.blank? || part.blank? || question_set.blank?

        Content.new(
          section: section,
          part: part,
          question_set: question_set,
          questions: questions
        )
      end

      def attempts_for(user)
        user.attempts
          .where(mockable: @exercise)
          .order(created_at: :desc)
          .includes(:answers)
      end

      def latest_attempt_for(user)
        attempts_for(user).first
      end

      def build_result(attempt, questions, filter:)
        answers_by_question_id = attempt.answers.where(question_id: questions.map(&:id)).index_by(&:question_id)
        normalized_filter = normalize_filter(filter)

        Result.new(
          attempt: attempt,
          answers_by_question_id: answers_by_question_id,
          total_count: questions.size,
          correct_count: questions.count { |question| answers_by_question_id[question.id]&.is_correct == true },
          answered_count: questions.count { |question| (answer = answers_by_question_id[question.id]) && answer.selected_choice.present? },
          filter: normalized_filter,
          display_questions: filter_questions(questions, answers_by_question_id, normalized_filter)
        )
      end

      private

      def normalize_filter(filter)
        filter.presence_in(%w[all correct wrong]) || "wrong"
      end

      def filter_questions(questions, answers_by_question_id, filter)
        case filter
        when "all"
          questions
        when "correct"
          questions.select { |question| answers_by_question_id[question.id]&.is_correct == true }
        else
          questions.select { |question| answers_by_question_id[question.id]&.is_correct != true }
        end
      end
    end
  end
end

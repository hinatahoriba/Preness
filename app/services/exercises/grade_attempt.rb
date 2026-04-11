module Exercises
  class GradeAttempt
    def self.call(user:, exercise:, question_set:, answers_by_question_id:)
      new(
        user:,
        exercise:,
        question_set:,
        answers_by_question_id:
      ).call
    end

    def initialize(user:, exercise:, question_set:, answers_by_question_id:)
      @user = user
      @exercise = exercise
      @question_set = question_set
      @answers_by_question_id = answers_by_question_id
    end

    def call
      questions = @question_set.questions.to_a
      attempt = Attempt.create!(user: @user, mockable: @exercise, completed_at: Time.current)

      Answer.transaction do
        questions.each do |question|
          selected_choice = @answers_by_question_id.fetch(question.id.to_s, nil).presence

          attempt.answers.create!(
            question:,
            selected_choice:,
            is_correct: selected_choice == question.correct_choice
          )
        end
      end

      attempt
    end
  end
end

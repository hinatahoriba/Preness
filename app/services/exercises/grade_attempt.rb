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
      attempt = Attempt.find_or_create_by!(user: @user, mockable: @exercise)

      existing_answers = attempt.answers.where(question_id: questions.map(&:id)).index_by(&:question_id)

      Answer.transaction do
        questions.each do |question|
          selected_choice = @answers_by_question_id.fetch(question.id.to_s, nil).presence
          is_correct = selected_choice.present? ? (selected_choice == question.correct_choice) : nil

          answer = existing_answers[question.id] || attempt.answers.build(question:)
          answer.selected_choice = selected_choice
          answer.is_correct = is_correct
          answer.save!
        end
      end

      attempt
    end
  end
end


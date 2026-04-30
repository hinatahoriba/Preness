module ExamSessions
  class PersistAnswers
    def self.call(attempt:, questions:, answers_by_question_id:)
      new(
        attempt: attempt,
        questions: questions,
        answers_by_question_id: answers_by_question_id
      ).call
    end

    def initialize(attempt:, questions:, answers_by_question_id:)
      @attempt = attempt
      @questions = questions
      @answers_by_question_id = answers_by_question_id
    end

    def call
      Answer.transaction do
        @questions.each do |question|
          selected_choice = @answers_by_question_id.fetch(question.id.to_s, nil).presence

          answer = @attempt.answers.find_or_initialize_by(question_id: question.id)
          answer.update!(
            selected_choice: selected_choice,
            is_correct: selected_choice == question.correct_choice
          )
        end
      end

      @attempt
    end
  end
end

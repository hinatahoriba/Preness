module Mocks
  class SavePartAnswers
    def self.call(attempt:, part:, answers_by_question_id:)
      new(attempt:, part:, answers_by_question_id:).call
    end

    def initialize(attempt:, part:, answers_by_question_id:)
      @attempt = attempt
      @part = part
      @answers_by_question_id = answers_by_question_id
    end

    def call
      questions = @part.question_sets.includes(:questions).flat_map(&:questions)

      Answer.transaction do
        questions.each do |question|
          selected_choice = @answers_by_question_id.fetch(question.id.to_s, nil).presence

          answer = @attempt.answers.find_or_initialize_by(question_id: question.id)
          answer.update!(
            selected_choice:,
            is_correct: selected_choice == question.correct_choice
          )
        end
      end
    end
  end
end

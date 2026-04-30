module ExamSessions
  class QuestionReviewPresenter
    attr_reader :question, :answer, :section_type

    def initialize(question:, answer:, section_type: nil)
      @question = question
      @answer = answer
      @section_type = section_type
    end

    def selected_choice
      answer&.selected_choice
    end

    def correct_choice
      question.correct_choice
    end

    def correct?
      answer&.is_correct == true
    end

    def selected_choice_display
      return "?" if selected_choice == "UNKNOWN"
      return "-" if selected_choice.blank?

      selected_choice.upcase
    end

    def selected_choice_text
      return "わからない" if selected_choice == "UNKNOWN"
      return "未回答" if selected_choice.blank?

      choice_text(selected_choice)
    end

    def correct_choice_text
      choice_text(correct_choice)
    end

    def wrong_reason
      return nil unless Question::CHOICES.include?(selected_choice)

      question.public_send("wrong_reason_#{selected_choice.downcase}")
    end

    def explanation_text
      question.explanation.presence || "解説はありません。"
    end

    def audio_url
      question.question_set.conversation_audio_url.presence ||
        question.conversation_audio_url.presence ||
        question.question_audio_url.presence
    end

    def passage
      question.question_set.passage.presence
    end

    def scripts
      question.question_set.scripts.presence || question.scripts.presence
    end

    def context_title
      return "リスニング原稿" if listening?

      "本文・問題背景"
    end

    def choices
      Question::CHOICES.map do |choice|
        {
          choice: choice,
          text: choice_text(choice),
          selected: choice == selected_choice,
          correct: choice == correct_choice
        }
      end
    end

    private

    def choice_text(choice)
      question.public_send("choice_#{choice.downcase}")
    end

    def listening?
      section_type.to_s.include?("listening")
    end
  end
end

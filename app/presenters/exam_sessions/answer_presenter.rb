module ExamSessions
  class AnswerPresenter
    attr_reader :title, :questions, :total_count, :answered_count, :form_id, :form_url,
                :submit_label, :layout_partial, :layout_locals, :secondary_links,
                :interrupt_confirm_path

    def initialize(title:, reading:, questions:, total_count:, answered_count:, form_id:, form_url:,
                   submit_label:, layout_partial:, layout_locals:, require_all_answered:,
                   secondary_links: [], timer_seconds: nil, timer_display: nil,
                   interrupt_confirm_path: nil)
      @title = title
      @reading = reading
      @questions = questions
      @total_count = total_count
      @answered_count = answered_count
      @form_id = form_id
      @form_url = form_url
      @submit_label = submit_label
      @layout_partial = layout_partial
      @layout_locals = layout_locals
      @require_all_answered = require_all_answered
      @secondary_links = secondary_links
      @timer_seconds = timer_seconds
      @timer_display = timer_display
      @interrupt_confirm_path = interrupt_confirm_path
    end

    def self.for_exercise(exercise:, section:, part:, question_set:, questions:, total_count:, answered_count:, attempt:)
      new(
        title: exercise_title(section: section, part: part, question_set: question_set),
        reading: section.section_type == "reading",
        questions: questions,
        total_count: total_count,
        answered_count: answered_count,
        form_id: "exercise-answer-form",
        form_url: Rails.application.routes.url_helpers.answer_exercise_path(exercise),
        submit_label: "採点する",
        layout_partial: layout_partial_for(section: section, part: part),
        layout_locals: layout_locals_for(
          mode: :exercise,
          section: section,
          part: part,
          question_set: question_set,
          question_sets: [question_set],
          questions: questions
        ),
        require_all_answered: true,
        secondary_links: exercise_links(exercise, attempt)
      )
    end

    def self.for_mock(mock:, attempt:, section:, part:, question_sets:, questions:, total_count:, answered_count:, submit_label:)
      new(
        title: mock_title(section: section, part: part),
        reading: section.section_type == "reading",
        questions: questions,
        total_count: total_count,
        answered_count: answered_count,
        form_id: "mock-answer-form-#{part.id}",
        form_url: Rails.application.routes.url_helpers.submit_part_mock_path(
          mock,
          section_id: section.id,
          part_id: part.id,
          attempt_id: attempt.id
        ),
        submit_label: submit_label,
        layout_partial: layout_partial_for(section: section, part: part),
        layout_locals: layout_locals_for(
          mode: :mock,
          section: section,
          part: part,
          question_set: question_sets.first,
          question_sets: question_sets,
          questions: questions
        ),
        require_all_answered: false,
        timer_seconds: ExamCatalog.section_time_limit_seconds(section.section_type),
        timer_display: ExamCatalog.section_time_limit_display(section.section_type),
        interrupt_confirm_path: Rails.application.routes.url_helpers.mocks_path
      )
    end

    def reading?
      @reading
    end

    def wrapper_class
      "#{reading? ? 'h-screen flex flex-col overflow-hidden' : 'min-h-screen'} bg-white"
    end

    def form_class
      reading? ? "flex-1 flex flex-col overflow-hidden" : ""
    end

    def controller_names
      timer? ? "exam-progress mock-timer" : "exam-progress"
    end

    def require_all_answered?
      @require_all_answered
    end

    def timer?
      @timer_seconds.present?
    end

    def timer_seconds
      @timer_seconds
    end

    def timer_display
      @timer_display
    end

    def interruptible?
      interrupt_confirm_path.present?
    end

    private

    def self.exercise_links(exercise, attempt)
      links = [
        {
          label: "一覧に戻る",
          path: Rails.application.routes.url_helpers.exercises_path
        }
      ]

      if attempt.present?
        links << {
          label: "結果履歴を見る",
          path: Rails.application.routes.url_helpers.history_exercise_path(exercise)
        }
      end

      links
    end

    def self.layout_partial_for(section:, part:)
      if section.section_type == "listening" && part.part_type == "part_a"
        "shared/exam/layouts/listening_part_a"
      elsif section.section_type == "listening"
        "shared/exam/layouts/listening_part_bc"
      elsif section.section_type == "structure"
        "shared/exam/layouts/structure"
      else
        "shared/exam/layouts/reading"
      end
    end

    def self.layout_locals_for(mode:, section:, part:, question_set:, question_sets:, questions:)
      if section.section_type == "listening" && part.part_type == "part_a"
        {
          questions: questions,
          single_use_audio: mode == :mock
        }
      elsif section.section_type == "listening"
        {
          question_sets: question_sets,
          part_label: ExamCatalog.part_label(part.part_type)&.upcase,
          single_use_audio: mode == :mock
        }
      elsif section.section_type == "structure"
        {
          questions: questions,
          part_label: ExamCatalog.part_label(part.part_type)&.upcase
        }
      else
        {
          question_sets: question_sets,
          tabbed: mode == :mock
        }
      end
    end

    def self.exercise_title(section:, part:, question_set:)
      section_label = ExamCatalog.section_label(section.section_type)
      part_label = ExamCatalog.part_label(part.part_type)

      if part_label.present? && section.section_type != "reading"
        "#{section_label} #{part_label} - Set#{question_set.display_order}"
      else
        "#{section_label} - Set#{question_set.display_order}"
      end
    end

    def self.mock_title(section:, part:)
      section_label = ExamCatalog.section_label(section.section_type).upcase
      part_label = ExamCatalog.part_label(part.part_type)

      title = "SECTION #{section.display_order}: #{section_label}"
      title += " - #{part_label.upcase}" if part_label.present?
      title
    end
  end
end

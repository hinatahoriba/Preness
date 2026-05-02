module ExamSessions
  module Flow
    class Diagnostic
      Step = Struct.new(:section, :part, keyword_init: true)

      DIRECTION_INTROS = {
        "listening" => {
          "part_a" => {
            count: "8問（約4分）",
            description: "音声は一度しか流れません。指示に従い、最も適切な選択肢を選んでください。"
          },
          "part_b" => {
            count: "2問（約2分）",
            description: "短い会話を聞き、各質問に最も適切な選択肢を選んでください。音声は一度しか流れません。"
          },
          "part_c" => {
            count: "2問（約3分）",
            description: "短い講義や会話を聞き、各質問に最も適切な選択肢を選んでください。音声は一度しか流れません。"
          }
        }.freeze,
        "structure" => {
          default: {
            count: "8問（約8分）",
            description: "各文を完成させる最も適切な選択肢、または誤りを含む箇所を選んでください。"
          }
        }.freeze,
        "reading" => {
          default: {
            count: "20問（約18分）",
            description: "各パッセージを読み、質問に最も適切な選択肢を選んでください。"
          }
        }.freeze
      }.freeze

      def initialize(diagnostic)
        @diagnostic = diagnostic
      end

      def first_step
        section = ordered_sections.first
        return nil unless section

        part = ordered_parts(section).first
        return nil unless part

        Step.new(section: section, part: part)
      end

      def next_step(current_part)
        current_section = ordered_sections.find { |s| s.id == current_part.section_id }
        return nil unless current_section

        next_part = ordered_parts(current_section).find { |p| p.display_order > current_part.display_order }
        return Step.new(section: current_section, part: next_part) if next_part

        next_section = ordered_sections.find { |s| s.display_order > current_section.display_order }
        return nil unless next_section

        next_section_part = ordered_parts(next_section).first
        return nil unless next_section_part

        Step.new(section: next_section, part: next_section_part)
      end

      def question_sets_for(part)
        part.question_sets.sort_by(&:display_order)
      end

      def questions_for(part)
        question_sets_for(part).flat_map { |qs| qs.questions.sort_by(&:display_order) }
      end

      def has_next_part?(part)
        next_step(part).present?
      end

      def submit_label_for(part)
        has_next_part?(part) ? "次のパートへ進む" : "採点して結果を見る"
      end

      def direction_intro_for(section, part)
        section_copy = DIRECTION_INTROS.fetch(section.section_type, {})
        section_copy.fetch(part.part_type, section_copy[:default])
      end

      def available_sections
        ordered_sections.map do |section|
          [ExamCatalog.section_label(section.section_type), section.section_type]
        end
      end

      def section_results(attempt)
        ordered_sections.map do |section|
          questions = questions_for_section(section)
          answers_by_question_id = attempt.answers
            .where(question_id: questions.map(&:id))
            .index_by(&:question_id)

          correct_count  = questions.count { |q| answers_by_question_id[q.id]&.is_correct == true }
          answered_count = questions.count { |q| (a = answers_by_question_id[q.id]) && a.selected_choice.present? }

          {
            section: section,
            questions: questions,
            answers_by_question_id: answers_by_question_id,
            correct_count: correct_count,
            answered_count: answered_count,
            total_count: questions.size
          }
        end
      end

      private

      def ordered_sections
        @ordered_sections ||= @diagnostic.sections.sort_by(&:display_order)
      end

      def ordered_parts(section)
        section.parts.sort_by(&:display_order)
      end

      def questions_for_section(section)
        ordered_parts(section).flat_map { |part| questions_for(part) }
      end
    end
  end
end

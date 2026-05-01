module Api
  module V1
    class DiagnosticsController < BaseController
      def create
        payload = diagnostic_payload

        diagnostic = nil

        ActiveRecord::Base.transaction do
          diagnostic = Diagnostic.create!(title: payload.fetch(:title))

          payload.fetch(:sections).each do |section_data|
            section = diagnostic.sections.create!(
              section_type:  section_data.fetch(:section_type),
              display_order: section_data.fetch(:display_order)
            )

            section_data.fetch(:parts).each do |part_data|
              part = section.parts.create!(
                part_type:     part_data.fetch(:part_type),
                display_order: part_data.fetch(:display_order)
              )

              part_data.fetch(:question_sets).each do |question_set_data|
                question_set = part.question_sets.create!(
                  passage:                question_set_data[:passage],
                  passage_theme:          question_set_data[:passage_theme],
                  conversation_audio_url: question_set_data[:conversation_audio_url],
                  scripts:                question_set_data[:scripts],
                  display_order:          question_set_data.fetch(:display_order)
                )

                question_set_data.fetch(:questions).each do |question_data|
                  question_set.questions.create!(
                    display_order:          question_data.fetch(:display_order),
                    question_text:          question_data.fetch(:question_text),
                    conversation_audio_url: question_data[:conversation_audio_url],
                    question_audio_url:     question_data[:question_audio_url],
                    choice_a:               question_data.fetch(:choice_a),
                    choice_b:               question_data.fetch(:choice_b),
                    choice_c:               question_data.fetch(:choice_c),
                    choice_d:               question_data.fetch(:choice_d),
                    correct_choice:         question_data.fetch(:correct_choice),
                    explanation:            question_data[:explanation],
                    tag:                    question_data[:tag],
                    wrong_reason_a:         question_data[:wrong_reason_a],
                    wrong_reason_b:         question_data[:wrong_reason_b],
                    wrong_reason_c:         question_data[:wrong_reason_c],
                    wrong_reason_d:         question_data[:wrong_reason_d]
                  )
                end
              end
            end
          end
        end

        render json: { status: "success", diagnostic_id: diagnostic.id, title: diagnostic.title }, status: :created
      end

      private

      def diagnostic_payload
        params.require(:title)
        params.require(:sections)

        params.permit(
          :title,
          sections: [
            :section_type,
            :display_order,
            { parts: [
              :part_type,
              :display_order,
              { question_sets: [
                :display_order,
                :passage,
                :passage_theme,
                :conversation_audio_url,
                :scripts,
                { questions: [
                  :display_order,
                  :question_text,
                  :conversation_audio_url,
                  :question_audio_url,
                  :scripts,
                  :choice_a,
                  :choice_b,
                  :choice_c,
                  :choice_d,
                  :correct_choice,
                  :explanation,
                  :tag,
                  :wrong_reason_a,
                  :wrong_reason_b,
                  :wrong_reason_c,
                  :wrong_reason_d
                ] }
              ] }
            ] }
          ]
        )
      end
    end
  end
end

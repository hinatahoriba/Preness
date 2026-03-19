module Api
  module V1
    class ExercisesController < BaseController
      VALID_PART_TYPES_BY_SECTION_TYPE = {
        "listening" => %w[part_a part_b part_c],
        "structure" => %w[part_a part_b],
        "reading" => %w[passages]
      }.freeze

      SECTION_DISPLAY_ORDERS = {
        "listening" => 1,
        "structure" => 2,
        "reading" => 3
      }.freeze

      PART_DISPLAY_ORDERS = {
        "part_a" => 1,
        "part_b" => 2,
        "part_c" => 3,
        "passages" => 1
      }.freeze

      def create
        payload = exercise_payload

        section_type = payload.fetch(:section_type)
        part_type = payload.fetch(:part_type)
        question_sets = payload.fetch(:question_sets, [])

        unless VALID_PART_TYPES_BY_SECTION_TYPE.fetch(section_type, []).include?(part_type)
          render json: { status: "error", errors: ["Validation failed: invalid combination of section_type and part_type"] },
            status: :unprocessable_entity
          return
        end

        if question_sets.blank?
          render json: { status: "error", errors: ["Validation failed: question_sets must have at least 1 item"] },
            status: :unprocessable_entity
          return
        end

        exercise_ids = []

        ActiveRecord::Base.transaction do
          question_sets.each do |question_set_data|
            exercise = Exercise.create!
            exercise_ids << exercise.id

            section = exercise.sections.create!(
              section_type: section_type,
              display_order: SECTION_DISPLAY_ORDERS.fetch(section_type)
            )

            part = section.parts.create!(
              part_type: part_type,
              display_order: PART_DISPLAY_ORDERS.fetch(part_type)
            )

            question_set = part.question_sets.create!(
              passage: question_set_data[:passage],
              conversation_audio_url: question_set_data[:conversation_audio_url],
              display_order: question_set_data.fetch(:display_order)
            )

            question_set_data.fetch(:questions).each do |question_data|
              question_set.questions.create!(
                display_order: question_data.fetch(:display_order),
                question_text: question_data.fetch(:question_text),
                question_audio_url: question_data[:question_audio_url],
                choice_a: question_data.fetch(:choice_a),
                choice_b: question_data.fetch(:choice_b),
                choice_c: question_data.fetch(:choice_c),
                choice_d: question_data.fetch(:choice_d),
                correct_choice: question_data.fetch(:correct_choice),
                explanation: question_data[:explanation]
              )
            end
          end
        end

        render json: { status: "success", exercise_ids: exercise_ids, created_count: exercise_ids.size }, status: :created
      end

      private

      def exercise_payload
        params.require(:section_type)
        params.require(:part_type)
        params.require(:question_sets)

        params.permit(
          :section_type,
          :part_type,
          question_sets: [
            :display_order,
            :passage,
            :conversation_audio_url,
            { questions: [
              :display_order,
              :question_text,
              :question_audio_url,
              :choice_a,
              :choice_b,
              :choice_c,
              :choice_d,
              :correct_choice,
              :explanation
            ] }
          ]
        )
      end
    end
  end
end

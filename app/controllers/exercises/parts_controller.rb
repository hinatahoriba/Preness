module Exercises
  class PartsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!

    def show
      section_type = params[:section_type]
      part_type    = params[:part_type]

      exercises = Exercise
        .visible
        .joins(sections: :parts)
        .where(sections: { section_type: section_type }, parts: { part_type: part_type })
        .includes(sections: { parts: { question_sets: :questions } })
        .distinct

      exercise_ids = exercises.map(&:id)
      latest_attempt_by_exercise_id = current_user.attempts
        .where(mockable_type: "Exercise", mockable_id: exercise_ids)
        .order(created_at: :desc)
        .includes(:answers)
        .each_with_object({}) do |attempt, hash|
          hash[attempt.mockable_id] ||= attempt
        end

      @show_presenter = ::Exercises::Parts::ShowPresenter.new(
        exercises: exercises,
        latest_attempt_by_exercise_id: latest_attempt_by_exercise_id,
        section_type: section_type,
        part_type: part_type
      )
    end
  end
end

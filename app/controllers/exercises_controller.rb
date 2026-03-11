class ExercisesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exercise, only: %i[answer result]
  before_action :set_exercise_content, only: %i[answer result]

  def index
    exercises = Exercise.includes(sections: { parts: :question_sets }).to_a

    @exercise_entries = exercises.filter_map do |exercise|
      section = exercise.sections.first
      part = section&.parts&.first
      question_set = part&.question_sets&.first

      next if section.blank? || part.blank? || question_set.blank?

      {
        exercise: exercise,
        section_type: section.section_type,
        section_display_order: section.display_order,
        part_type: part.part_type,
        part_display_order: part.display_order,
        set_number: question_set.display_order
      }
    end

    @exercise_entries.sort_by! do |entry|
      [
        entry.fetch(:section_display_order),
        entry.fetch(:part_display_order),
        entry.fetch(:set_number),
        entry.fetch(:exercise).id
      ]
    end

    @exercise_entries_by_section_type = @exercise_entries.group_by { _1.fetch(:section_type) }
  end

  def answer
    if request.post?
      Exercises::GradeAttempt.call(
        user: current_user,
        exercise: @exercise,
        question_set: @question_set,
        answers_by_question_id: answers_params
      )

      redirect_to result_exercise_path(@exercise), notice: "採点が完了しました。"
      return
    end

    load_saved_answers
  rescue ActiveRecord::RecordInvalid => e
    load_saved_answers
    flash.now[:alert] = e.message
    render :answer, status: :unprocessable_entity
  end

  def result
    @attempt = current_user.attempts.find_by(mockable: @exercise)

    if @attempt.blank?
      redirect_to answer_exercise_path(@exercise), alert: "まだ採点されていません。"
      return
    end

    @answers_by_question_id = @attempt.answers.where(question_id: @questions.map(&:id)).index_by(&:question_id)

    @total_count = @questions.size
    @correct_count = @questions.count { @answers_by_question_id[_1.id]&.is_correct == true }
    @answered_count = @questions.count { @answers_by_question_id[_1.id]&.selected_choice.present? }
    
    @filter = params[:filter].presence || 'wrong'
    @display_questions = case @filter
                         when 'all'
                           @questions
                         when 'correct'
                           @questions.select { @answers_by_question_id[_1.id]&.is_correct == true }
                         when 'wrong'
                           @questions.select { @answers_by_question_id[_1.id]&.is_correct != true }
                         else
                           @questions.select { @answers_by_question_id[_1.id]&.is_correct != true }
                         end
  end

  private

  def set_exercise
    @exercise = Exercise.includes(sections: { parts: { question_sets: :questions } }).find(params[:id])
  end

  def set_exercise_content
    @section = @exercise.sections.first
    @part = @section&.parts&.first
    @question_set = @part&.question_sets&.first
    @questions = @question_set&.questions&.to_a || []

    raise ActiveRecord::RecordNotFound, "Exercise content is missing" if @section.blank? || @part.blank? || @question_set.blank?
  end

  def load_saved_answers
    attempt = current_user.attempts.find_by(mockable: @exercise)
    answers_by_question_id = attempt&.answers&.where(question_id: @questions.map(&:id))&.index_by(&:question_id) || {}

    @attempt = attempt
    @answers_by_question_id = answers_by_question_id
    @total_count = @questions.size
    @answered_count = @questions.count { answers_by_question_id[_1.id]&.selected_choice.present? }
  end

  def answers_params
    params.permit(answers: {}).fetch(:answers, {}).to_h
  end
end


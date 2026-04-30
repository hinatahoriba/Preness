class ExercisesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exercise, only: %i[answer history result]
  before_action :set_flow, only: %i[answer history result]
  before_action :set_exercise_content, only: %i[answer history result]

  def index
    exercises = Exercise.includes(sections: { parts: { question_sets: :questions } }).to_a

    exercise_ids = exercises.map(&:id)
    attempts = current_user.attempts
      .where(mockable_type: "Exercise", mockable_id: exercise_ids)
      .order(created_at: :desc)
      .includes(:answers)
    latest_attempt_by_exercise_id = attempts.each_with_object({}) do |attempt, hash|
      hash[attempt.mockable_id] ||= attempt
    end

    @index_presenter = Exercises::IndexPresenter.new(
      exercises: exercises,
      latest_attempt_by_exercise_id: latest_attempt_by_exercise_id
    )
  end

  def answer
    if request.post?
      @attempt = Attempt.create!(user: current_user, mockable: @exercise, completed_at: Time.current)
      ExamSessions::PersistAnswers.call(
        attempt: @attempt,
        questions: @questions,
        answers_by_question_id: answers_params
      )

      redirect_to result_exercise_path(@exercise), notice: "採点が完了しました。"
      return
    end

    load_saved_answers
    @answer_presenter = build_answer_presenter
  rescue ActiveRecord::RecordInvalid => e
    load_saved_answers
    @answer_presenter = build_answer_presenter
    flash.now[:alert] = e.message
    render :answer, status: :unprocessable_entity
  end

  def history
    @attempts = @flow.attempts_for(current_user)

    if @attempts.empty?
      redirect_to answer_exercise_path(@exercise), alert: "まだ採点されていません。"
      return
    end

    @history_presenter = Exercises::HistoryPresenter.new(
      attempts: @attempts,
      total_questions: @questions.size
    )
  end

  def result
    @attempt = if params[:attempt_id].present?
                 current_user.attempts.find(params[:attempt_id])
               else
                 @flow.latest_attempt_for(current_user)
               end

    if @attempt.blank?
      redirect_to answer_exercise_path(@exercise), alert: "まだ採点されていません。"
      return
    end

    result = @flow.build_result(@attempt, @questions, filter: params[:filter])
    @answers_by_question_id = result.answers_by_question_id
    @total_count = result.total_count
    @correct_count = result.correct_count
    @answered_count = result.answered_count
    @filter = result.filter
    @display_questions = result.display_questions
    @result_presenter = Exercises::ResultPresenter.new(
      correct_count: @correct_count,
      total_count: @total_count
    )
  end

  private

  def set_exercise
    @exercise = Exercise.includes(sections: { parts: { question_sets: :questions } }).find(params[:id])
  end

  def set_flow
    @flow = ExamSessions::Flow::Exercise.new(@exercise)
  end

  def set_exercise_content
    content = @flow.content!
    @section = content.section
    @part = content.part
    @question_set = content.question_set
    @questions = content.questions
  end

  def load_saved_answers
    @attempt = @flow.latest_attempt_for(current_user)
    @answers_by_question_id = {}
    @total_count = @questions.size
    @answered_count = 0
  end

  def build_answer_presenter
    ExamSessions::AnswerPresenter.for_exercise(
      exercise: @exercise,
      section: @section,
      part: @part,
      question_set: @question_set,
      questions: @questions,
      total_count: @total_count,
      answered_count: @answered_count,
      attempt: @attempt
    )
  end

  def answers_params
    params.permit(answers: {}).fetch(:answers, {}).to_h
  end
end

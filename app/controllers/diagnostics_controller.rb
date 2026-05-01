class DiagnosticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diagnostic, except: :index
  before_action :set_flow,       except: :index
  before_action :set_attempt,       only: %i[direction answer submit_part result]
  before_action :set_section_part,  only: %i[direction answer submit_part]

  # GET /diagnostics
  def index
    diagnostics = Diagnostic.all.order(:created_at)
    attempts_by_diagnostic_id = current_user.attempts
      .where(mockable: diagnostics)
      .index_by(&:mockable_id)
    @diagnostics = diagnostics
    @attempts_by_diagnostic_id = attempts_by_diagnostic_id
  end

  # GET /diagnostics/:id/guideline
  def guideline
  end

  # GET /diagnostics/:id/ready
  def ready
    attempt = current_user.attempts.find_by(mockable: @diagnostic)

    if attempt&.completed_at.present?
      redirect_to result_diagnostic_path(@diagnostic, attempt_id: attempt.id)
      return
    end

    if attempt&.completed_at.nil? && attempt.present?
      redirect_to diagnostics_path, alert: "この実力診断は途中で中断されたため再開できません。"
    end
  end

  # POST /diagnostics/:id/start
  def start
    existing = current_user.attempts.find_by(mockable: @diagnostic)

    if existing&.completed_at.present?
      redirect_to result_diagnostic_path(@diagnostic, attempt_id: existing.id)
      return
    end

    if existing.present?
      redirect_to diagnostics_path, alert: "この実力診断は途中で中断されたため再開できません。"
      return
    end

    @attempt = Attempt.create!(
      user: current_user,
      mockable: @diagnostic,
      completed_at: nil
    )

    first_step = @flow.first_step

    if first_step.nil?
      redirect_to guideline_diagnostic_path(@diagnostic), alert: "試験データが正しく設定されていません。"
      return
    end

    redirect_to direction_diagnostic_path(
      @diagnostic,
      section_id: first_step.section.id,
      part_id:    first_step.part.id,
      attempt_id: @attempt.id
    )
  end

  # GET /diagnostics/:id/direction?section_id=X&part_id=Y&attempt_id=Z
  def direction
    @direction_intro = @flow.direction_intro_for(@section, @part)
    @answer_url = answer_diagnostic_path(
      @diagnostic,
      section_id: @section.id,
      part_id:    @part.id,
      attempt_id: @attempt.id
    )
    @direction_presenter = ::Mocks::DirectionPresenter.new(
      section: @section,
      part: @part,
      intro: @direction_intro,
      answer_url: @answer_url,
      duration_seconds: ExamCatalog::DIRECTION_COUNTDOWN_SECONDS
    )
    render "mocks/direction"
  end

  # GET /diagnostics/:id/answer?section_id=X&part_id=Y&attempt_id=Z
  def answer
    @question_sets  = @flow.question_sets_for(@part)
    @questions      = @flow.questions_for(@part)
    @total_count    = @questions.size
    @answered_count = 0
    @submit_label   = @flow.submit_label_for(@part)
    @answer_presenter = ExamSessions::AnswerPresenter.for_diagnostic(
      diagnostic:     @diagnostic,
      attempt:        @attempt,
      section:        @section,
      part:           @part,
      question_sets:  @question_sets,
      questions:      @questions,
      total_count:    @total_count,
      answered_count: @answered_count,
      submit_label:   @submit_label
    )
    render "mocks/answer"
  end

  # POST /diagnostics/:id/submit_part
  def submit_part
    ExamSessions::PersistAnswers.call(
      attempt:                @attempt,
      questions:              @flow.questions_for(@part),
      answers_by_question_id: answers_params
    )

    next_step = @flow.next_step(@part)

    if next_step
      redirect_to direction_diagnostic_path(
        @diagnostic,
        section_id: next_step.section.id,
        part_id:    next_step.part.id,
        attempt_id: @attempt.id
      )
    else
      @attempt.update!(completed_at: Time.current)
      ::Diagnostics::AnalyzeResultJob.perform_later(@attempt.id)
      redirect_to result_diagnostic_path(@diagnostic, attempt_id: @attempt.id)
    end
  end

  # GET /diagnostics/:id/result?attempt_id=Z
  def result
    @section_results   = @flow.section_results(@attempt)
    @filter            = params[:filter].presence || "wrong"
    @part_filter       = params[:part_filter].presence || "all"
    @available_sections = @flow.available_sections
    @result_presenter  = ::Mocks::ResultPresenter.new(
      section_results: @section_results,
      filter:          @filter,
      part_filter:     @part_filter
    )
  end

  private

  def set_diagnostic
    @diagnostic = Diagnostic
      .includes(sections: { parts: { question_sets: :questions } })
      .find(params[:id])
  end

  def set_flow
    @flow = ExamSessions::Flow::Diagnostic.new(@diagnostic)
  end

  def set_attempt
    attempt_id = params[:attempt_id]
    if attempt_id.blank?
      redirect_to guideline_diagnostic_path(@diagnostic), alert: "試験を最初からやり直してください。"
      return
    end
    @attempt = current_user.attempts.find(attempt_id)
  end

  def set_section_part
    @section = @diagnostic.sections.find(params[:section_id])
    @part    = @section.parts.find(params[:part_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to guideline_diagnostic_path(@diagnostic), alert: "セクションまたはパートが見つかりません。"
  end

  def answers_params
    return {} if params[:answers].blank?
    params[:answers].permit!.to_h
  end
end

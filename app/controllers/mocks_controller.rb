class MocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mock, except: :index
  before_action :set_flow, except: :index
  before_action :ensure_purchased!, only: %i[guideline ready start direction answer submit_part result]
  before_action :ensure_can_start_mock, only: %i[ready start]
  before_action :set_attempt,       only: %i[direction answer submit_part result]
  before_action :set_section_part,  only: %i[direction answer submit_part]

  # GET /mocks
  def index
    mocks = Mock.all.order(:created_at)
    attempts_by_mock_id = current_user.attempts.where(mockable: mocks).index_by(&:mockable_id)
    purchased_mock_ids = current_user.purchases.completed.where(mock: mocks).pluck(:mock_id).to_set
    @index_presenter = ::Mocks::IndexPresenter.new(
      mocks: mocks,
      attempts_by_mock_id: attempts_by_mock_id,
      purchased_mock_ids: purchased_mock_ids
    )
  end

  # GET /mocks/:id/guideline
  def guideline
  end

  # GET /mocks/:id/ready
  def ready
  end

  # POST /mocks/:id/start
  # Attempt を作成して最初の direction 画面へ遷移
  def start
    @attempt = Attempt.create!(
      user: current_user,
      mockable: @mock,
      completed_at: nil
    )

    first_step = @flow.first_step

    if first_step.nil?
      redirect_to guideline_mock_path(@mock), alert: "試験データが正しく設定されていません。"
      return
    end

    redirect_to direction_mock_path(
      @mock,
      section_id: first_step.section.id,
      part_id:    first_step.part.id,
      attempt_id: @attempt.id
    )
  end

  # GET /mocks/:id/direction?section_id=X&part_id=Y&attempt_id=Z
  def direction
    @direction_intro = @flow.direction_intro_for(@section, @part)
    @answer_url = answer_mock_path(
      @mock,
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
  end

  # GET /mocks/:id/answer?section_id=X&part_id=Y&attempt_id=Z
  def answer
    @question_sets = @flow.question_sets_for(@part)
    @questions = @flow.questions_for(@part)
    @total_count = @questions.size
    @answered_count = 0
    @submit_label = @flow.submit_label_for(@part)
    @answer_presenter = ExamSessions::AnswerPresenter.for_mock(
      mock: @mock,
      attempt: @attempt,
      section: @section,
      part: @part,
      question_sets: @question_sets,
      questions: @questions,
      total_count: @total_count,
      answered_count: @answered_count,
      submit_label: @submit_label
    )
  end

  # POST /mocks/:id/submit_part
  def submit_part
    ExamSessions::PersistAnswers.call(
      attempt: @attempt,
      questions: @flow.questions_for(@part),
      answers_by_question_id: answers_params
    )

    next_step = @flow.next_step(@part)

    if next_step
      redirect_to direction_mock_path(
        @mock,
        section_id: next_step.section.id,
        part_id:    next_step.part.id,
        attempt_id: @attempt.id
      )
    else
      @attempt.update!(completed_at: Time.current)
      ::Mocks::AnalyzeMockResultJob.perform_later(@attempt.id)
      redirect_to result_mock_path(@mock, attempt_id: @attempt.id)
    end
  end

  # GET /mocks/:id/result?attempt_id=Z
  def result
    @section_results = @flow.section_results(@attempt)
    @filter = params[:filter].presence || "wrong"
    @part_filter = params[:part_filter].presence || "all"
    @available_sections = @flow.available_sections
    @result_presenter = ::Mocks::ResultPresenter.new(
      section_results: @section_results,
      filter: @filter,
      part_filter: @part_filter
    )
  end

  private

  def set_mock
    @mock = Mock.includes(sections: { parts: { question_sets: :questions } })
                .find(params[:id])
  end

  def set_flow
    @flow = ExamSessions::Flow::Mock.new(@mock)
  end

  def ensure_purchased!
    return if current_user.purchased?(@mock)

    redirect_to mocks_path, alert: "この模擬試験を受けるには購入が必要です。"
  end

  def ensure_can_start_mock
    attempt = current_user.attempts.find_by(mockable: @mock)

    return if attempt.nil?

    if attempt.completed_at.present?
      redirect_to result_mock_path(@mock, attempt_id: attempt.id)
      return
    end

    redirect_to mocks_path, alert: "この模擬試験は途中で中断されたため再開できません。"
  end

  def set_attempt
    attempt_id = params[:attempt_id]
    if attempt_id.blank?
      redirect_to guideline_mock_path(@mock), alert: "試験を最初からやり直してください。"
      return
    end
    @attempt = current_user.attempts.find(attempt_id)
  end

  def set_section_part
    @section = @mock.sections.find(params[:section_id])
    @part    = @section.parts.find(params[:part_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to guideline_mock_path(@mock), alert: "セクションまたはパートが見つかりません。"
  end

  def answers_params
    return {} if params[:answers].blank?
    params[:answers].permit!.to_h
  end

end

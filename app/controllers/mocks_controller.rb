class MocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mock, except: :index
  before_action :ensure_can_start_mock, only: %i[ready start]
  before_action :set_attempt,       only: %i[direction answer submit_part result]
  before_action :set_section_part,  only: %i[direction answer submit_part]

  # GET /mocks
  def index
    @mocks = Mock.all.order(:created_at)
    @attempts_by_mock_id = current_user.attempts.where(mockable: @mocks).index_by(&:mockable_id)
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

    first_section = @mock.sections.order(:display_order).first
    first_part    = first_section&.parts&.order(:display_order)&.first

    if first_section.nil? || first_part.nil?
      redirect_to guideline_mock_path(@mock), alert: "試験データが正しく設定されていません。"
      return
    end

    redirect_to direction_mock_path(
      @mock,
      section_id: first_section.id,
      part_id:    first_part.id,
      attempt_id: @attempt.id
    )
  end

  # GET /mocks/:id/direction?section_id=X&part_id=Y&attempt_id=Z
  def direction
    @answer_url = answer_mock_path(
      @mock,
      section_id: @section.id,
      part_id:    @part.id,
      attempt_id: @attempt.id
    )
  end

  # GET /mocks/:id/answer?section_id=X&part_id=Y&attempt_id=Z
  def answer
    @questions = @part.question_sets
      .order(:display_order)
      .includes(:questions)
      .flat_map { |qs| qs.questions.order(:display_order) }

    @total_count    = @questions.size
    @answered_count = 0
  end

  # POST /mocks/:id/submit_part
  def submit_part
    Mocks::SavePartAnswers.call(
      attempt: @attempt,
      part:    @part,
      answers_by_question_id: answers_params
    )

    next_part = helpers.mock_next_part_for(@mock, @part)
    next_section = next_part ? Section.find(next_part.section_id) : nil

    if next_part
      redirect_to direction_mock_path(
        @mock,
        section_id: next_section.id,
        part_id:    next_part.id,
        attempt_id: @attempt.id
      )
    else
      @attempt.update!(completed_at: Time.current)
      Mocks::AnalyzeMockResultJob.perform_later(@attempt.id)
      redirect_to result_mock_path(@mock, attempt_id: @attempt.id)
    end
  end

  # GET /mocks/:id/result?attempt_id=Z
  def result
    @section_results = @mock.sections.order(:display_order).map do |section|
      questions = section.parts.order(:display_order).flat_map do |part|
        part.question_sets.order(:display_order).flat_map do |qs|
          qs.questions.order(:display_order)
        end
      end

      answers_by_question_id = @attempt.answers
        .where(question_id: questions.map(&:id))
        .index_by(&:question_id)

      correct_count  = questions.count { answers_by_question_id[_1.id]&.is_correct == true }
      answered_count = questions.count { answers_by_question_id[_1.id].present? }

      {
        section:                section,
        questions:              questions,
        answers_by_question_id: answers_by_question_id,
        correct_count:          correct_count,
        answered_count:         answered_count,
        total_count:            questions.size
      }
    end

    @filter = params[:filter].presence || "wrong"
  end

  private

  def set_mock
    @mock = Mock.includes(sections: { parts: { question_sets: :questions } })
                .find(params[:id])
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

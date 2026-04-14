class MockReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mock
  before_action :set_attempt

  rescue_from StandardError do |error|
    Rails.logger.error "[MockReportsController] #{error.class}: #{error.message}\n#{error.backtrace&.first(5)&.join("\n")}"
    redirect_path = (@mock && @attempt) ?
      result_mock_path(@mock, attempt_id: @attempt.id) :
      mocks_path
    redirect_to redirect_path, alert: "分析レポートの読み込みに失敗しました。採点結果を確認してください。"
  end

  def show
    @report = @attempt.mock_analysis_report

    if @report&.completed?
      answers_map = @attempt.answers.includes(:question).index_by(&:question_id)
      @parts_accuracy = build_report_parts_accuracy(@mock, answers_map)
      @tag_accuracy   = build_report_tag_accuracy(@mock, answers_map)
      @target_score   = @attempt.user.user_profile&.itp_target_score
    end

    render "mocks/report"
  end

  private

  def set_mock
    @mock = Mock.includes(sections: { parts: { question_sets: :questions } })
                .find(params[:id])
  end

  def set_attempt
    attempt_id = params[:attempt_id]
    if attempt_id.blank?
      redirect_to guideline_mock_path(@mock), alert: "試験を最初からやり直してください。"
      return
    end
    @attempt = current_user.attempts.find(attempt_id)
  end

  LISTENING_PART_TOTALS = { "part_a" => 30, "part_b" => 8, "part_c" => 12 }.freeze
  STRUCTURE_PART_TOTALS = { "part_a" => 15, "part_b" => 25 }.freeze
  READING_QUESTIONS_PER_SET = 10
  READING_SET_COUNT = 5

  def build_report_parts_accuracy(mock, answers_map)
    {
      listening: build_report_listening(mock, answers_map),
      structure: build_report_structure(mock, answers_map),
      reading:   build_report_reading(mock, answers_map)
    }
  end

  def build_report_listening(mock, answers_map)
    section = mock.sections.find { |s| s.section_type == "listening" }
    return nil unless section

    result = {}
    LISTENING_PART_TOTALS.each_key do |pt|
      part = section.parts.find { |p| p.part_type == pt }
      questions = part ? part.question_sets.flat_map(&:questions) : []
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      total = LISTENING_PART_TOTALS[pt]
      result[pt.to_sym] = { correct: correct, total: total, pct: total > 0 ? (correct * 100.0 / total).round : 0 }
    end
    result
  end

  def build_report_structure(mock, answers_map)
    section = mock.sections.find { |s| s.section_type == "structure" }
    return nil unless section

    result = {}
    STRUCTURE_PART_TOTALS.each_key do |pt|
      part = section.parts.find { |p| p.part_type == pt }
      questions = part ? part.question_sets.flat_map(&:questions) : []
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      total = STRUCTURE_PART_TOTALS[pt]
      result[pt.to_sym] = { correct: correct, total: total, pct: total > 0 ? (correct * 100.0 / total).round : 0 }
    end
    result
  end

  def build_report_reading(mock, answers_map)
    section = mock.sections.find { |s| s.section_type == "reading" }
    return nil unless section

    part = section.parts.find { |p| p.part_type == "passages" }
    return nil unless part

    question_sets = part.question_sets.sort_by(&:display_order).first(READING_SET_COUNT)
    question_sets.each_with_index.map do |qs, idx|
      questions = qs.questions
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      {
        label:         "Reading %02d" % (idx + 1),
        passage_thema: qs.passage_thema.presence,
        correct:       correct,
        total:         READING_QUESTIONS_PER_SET,
        pct:           (correct * 100.0 / READING_QUESTIONS_PER_SET).round
      }
    end
  end

  def build_report_tag_accuracy(mock, answers_map)
    all_questions = mock.sections.flat_map do |section|
      section.parts.flat_map do |part|
        part.question_sets.flat_map(&:questions)
      end
    end

    all_questions.select(&:tag).group_by(&:tag).transform_values do |questions|
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      total = questions.size
      { correct: correct, total: total, pct: total > 0 ? (correct * 100.0 / total).round : 0 }
    end
  end
end

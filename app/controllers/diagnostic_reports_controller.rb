class DiagnosticReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diagnostic
  before_action :set_attempt

  rescue_from StandardError do |error|
    Rails.logger.error "[DiagnosticReportsController] #{error.class}: #{error.message}\n#{error.backtrace&.first(5)&.join("\n")}"
    redirect_path = (@diagnostic && @attempt) ?
      result_diagnostic_path(@diagnostic, attempt_id: @attempt.id) :
      diagnostics_path
    redirect_to redirect_path, alert: "分析レポートの読み込みに失敗しました。試験結果を確認してください。"
  end

  def show
    @report = @attempt.analysis_report

    if @report&.completed?
      answers_map = @attempt.answers.includes(:question).index_by(&:question_id)
      @parts_accuracy = build_report_parts_accuracy(@diagnostic, answers_map)
      @tag_accuracy   = build_report_tag_accuracy(@diagnostic, answers_map)
      @target_score   = @attempt.user.user_profile&.itp_target_score
      @all_scores     = current_user.attempts
        .joins(:analysis_report)
        .where.not(completed_at: nil)
        .where(mockable_type: "Diagnostic")
        .where(analysis_reports: { status: :completed })
        .order(completed_at: :asc)
        .pluck("analysis_reports.total_score")
    end
  end

  private

  def set_diagnostic
    @diagnostic = Diagnostic.includes(sections: { parts: { question_sets: :questions } })
                             .find(params[:id])
  end

  def set_attempt
    attempt_id = params[:attempt_id]
    if attempt_id.blank?
      redirect_to guideline_diagnostic_path(@diagnostic), alert: "試験を最初からやり直してください。"
      return
    end
    @attempt = current_user.attempts.find(attempt_id)
  end

  def build_report_parts_accuracy(diagnostic, answers_map)
    {
      listening: build_report_listening(diagnostic, answers_map),
      structure: build_report_structure(diagnostic, answers_map),
      reading:   build_report_reading(diagnostic, answers_map)
    }
  end

  def build_report_listening(diagnostic, answers_map)
    section = diagnostic.sections.find { |s| s.section_type == "listening" }
    return nil unless section

    ExamCatalog.diagnostic_part_totals("listening").each_with_object({}) do |(pt, total), result|
      part = section.parts.find { |p| p.part_type == pt }
      questions = part ? part.question_sets.flat_map(&:questions) : []
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      result[pt.to_sym] = { correct: correct, total: total, pct: total > 0 ? (correct * 100.0 / total).round : 0 }
    end
  end

  def build_report_structure(diagnostic, answers_map)
    section = diagnostic.sections.find { |s| s.section_type == "structure" }
    return nil unless section

    ExamCatalog.diagnostic_part_totals("structure").each_with_object({}) do |(pt, total), result|
      part = section.parts.find { |p| p.part_type == pt }
      questions = part ? part.question_sets.flat_map(&:questions) : []
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      result[pt.to_sym] = { correct: correct, total: total, pct: total > 0 ? (correct * 100.0 / total).round : 0 }
    end
  end

  def build_report_reading(diagnostic, answers_map)
    section = diagnostic.sections.find { |s| s.section_type == "reading" }
    return nil unless section

    part = section.parts.find { |p| p.part_type == "passages" }
    return nil unless part

    question_sets = part.question_sets.sort_by(&:display_order).first(ExamCatalog::DIAGNOSTIC_READING_SET_COUNT)
    question_sets.each_with_index.map do |qs, idx|
      questions = qs.questions
      correct = questions.count { |q| answers_map[q.id]&.is_correct == true }
      {
        label:         "Reading %02d" % (idx + 1),
        passage_theme: qs.passage_theme.presence,
        correct:       correct,
        total:         ExamCatalog::DIAGNOSTIC_READING_QUESTIONS_PER_SET,
        pct:           (correct * 100.0 / ExamCatalog::DIAGNOSTIC_READING_QUESTIONS_PER_SET).round
      }
    end
  end

  def build_report_tag_accuracy(diagnostic, answers_map)
    all_questions = diagnostic.sections.flat_map do |section|
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

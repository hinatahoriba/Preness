module MocksHelper
  DIRECTION_COUNTDOWN_SECONDS = ExamCatalog::DIRECTION_COUNTDOWN_SECONDS

  def mock_section_label(section_type)
    exam_section_label(section_type)
  end

  def mock_part_label(part_type)
    exam_part_label(part_type)
  end

  # ヘッダー用タイトル（例: "SECTION 1: LISTENING COMPREHENSION - PART A"）
  def mock_section_part_title(section, part)
    exam_section_part_title(section, part)
  end

  # Direction 画面の説明テキスト
  def mock_direction_intro(section, part)
    case section.section_type
    when "listening"
      case part.part_type
      when "part_a"
        { count: "30問（約15分）", description: "音声は一度しか流れません。指示に従い、最も適切な選択肢を選んでください。" }
      when "part_b"
        { count: "7問（約8分）", description: "短い会話を聞き、各質問に最も適切な選択肢を選んでください。音声は一度しか流れません。" }
      when "part_c"
        { count: "13問（約12分）", description: "短い講義や会話を聞き、各質問に最も適切な選択肢を選んでください。音声は一度しか流れません。" }
      end
    when "structure"
      { count: "40問（約25分）", description: "各文を完成させる最も適切な選択肢、または誤りを含む箇所を選んでください。" }
    when "reading"
      { count: "50問（約55分）", description: "各パッセージを読み、質問に最も適切な選択肢を選んでください。" }
    end
  end

  # タイムリミット（秒）
  def mock_section_time_limit_seconds(section_type)
    exam_section_time_limit_seconds(section_type)
  end

  # "35:00" フォーマットで返す
  def mock_section_time_limit_display(section_type)
    exam_section_time_limit_display(section_type)
  end

  # 現在の Part の次の Part を返す（同Section内 → 次Section → nil）
  def mock_next_part_for(mock, current_part)
    current_section = mock.sections.find { |s| s.id == current_part.section_id }

    # 同Section内の次のPart
    next_in_section = current_section.parts
      .sort_by(&:display_order)
      .find { |p| p.display_order > current_part.display_order }
    return next_in_section if next_in_section

    # 次のSectionの最初のPart
    next_section = mock.sections
      .sort_by(&:display_order)
      .find { |s| s.display_order > current_section.display_order }
    next_section&.parts&.min_by(&:display_order)
  end

  def mock_has_next_part?(mock, current_part)
    mock_next_part_for(mock, current_part).present?
  end
end

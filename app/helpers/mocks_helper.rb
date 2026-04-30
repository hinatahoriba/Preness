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

  # タイムリミット（秒）
  def mock_section_time_limit_seconds(section_type)
    exam_section_time_limit_seconds(section_type)
  end

  # "35:00" フォーマットで返す
  def mock_section_time_limit_display(section_type)
    exam_section_time_limit_display(section_type)
  end
end

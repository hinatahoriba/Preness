module ExamUiHelper
  def exam_section_label(section_type)
    ExamCatalog.section_label(section_type)
  end

  def exam_part_label(part_type)
    ExamCatalog.part_label(part_type)
  end

  def exam_set_title(section_type:, part_type:, set_number:)
    section_label = exam_section_label(section_type)
    part_label = exam_part_label(part_type)

    if part_label.present? && section_type != "reading"
      "#{section_label} #{part_label} - Set#{set_number}"
    else
      "#{section_label} - Set#{set_number}"
    end
  end

  def exam_section_part_title(section, part)
    section_label = exam_section_label(section.section_type).upcase
    part_label = exam_part_label(part.part_type)

    title = "SECTION #{section.display_order}: #{section_label}"
    title += " - #{part_label.upcase}" if part_label.present?
    title
  end

  def exam_section_time_limit_seconds(section_type)
    ExamCatalog.section_time_limit_seconds(section_type)
  end

  def exam_section_time_limit_display(section_type)
    ExamCatalog.section_time_limit_display(section_type)
  end
end

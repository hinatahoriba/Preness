module ExercisesHelper
  def exercise_section_label(section_type)
    exam_section_label(section_type)
  end

  def exercise_part_label(part_type)
    exam_part_label(part_type)
  end

  def exercise_set_title(section_type:, part_type:, set_number:)
    exam_set_title(section_type: section_type, part_type: part_type, set_number: set_number)
  end
end

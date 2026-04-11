module ExercisesHelper
  SECTION_LABELS = {
    "listening" => "Listening Comprehension",
    "structure" => "Structure and Written Expression",
    "reading" => "Reading Comprehension"
  }.freeze

  PART_LABELS = {
    "part_a" => "Part A",
    "part_b" => "Part B",
    "part_c" => "Part C",
    "passages" => nil
  }.freeze

  def exercise_section_label(section_type)
    SECTION_LABELS.fetch(section_type, section_type)
  end

  def exercise_part_label(part_type)
    PART_LABELS.fetch(part_type, part_type)
  end

  def exercise_set_title(section_type:, part_type:, set_number:)
    section_label = exercise_section_label(section_type)
    part_label = exercise_part_label(part_type)

    if part_label.present? && section_type != "reading"
      "#{section_label} #{part_label} - Set#{set_number}"
    else
      "#{section_label} - Set#{set_number}"
    end
  end

end

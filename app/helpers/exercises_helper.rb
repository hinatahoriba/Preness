module ExercisesHelper
  SECTION_LABELS = {
    "listening" => "リスニング",
    "structure" => "文法",
    "reading" => "読解"
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
      "#{section_label} #{part_label} - セット#{set_number}"
    else
      "#{section_label} - セット#{set_number}"
    end
  end

  def question_choice_text(question, choice)
    case choice
    when "A" then question.choice_a
    when "B" then question.choice_b
    when "C" then question.choice_c
    when "D" then question.choice_d
    end
  end
end

module ExamCatalog
  extend self

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

  SECTION_TIME_LIMITS = {
    "listening" => 35 * 60,
    "structure" => 25 * 60,
    "reading" => 55 * 60
  }.freeze

  PART_TOTALS = {
    "listening" => {
      "part_a" => 30,
      "part_b" => 8,
      "part_c" => 12
    }.freeze,
    "structure" => {
      "part_a" => 15,
      "part_b" => 25
    }.freeze
  }.freeze

  READING_QUESTIONS_PER_SET = 10
  READING_SET_COUNT = 5
  DIRECTION_COUNTDOWN_SECONDS = 40

  def section_label(section_type)
    SECTION_LABELS.fetch(section_type, section_type)
  end

  def part_label(part_type)
    PART_LABELS.fetch(part_type, part_type)
  end

  def section_time_limit_seconds(section_type)
    SECTION_TIME_LIMITS.fetch(section_type, 0)
  end

  def section_time_limit_display(section_type)
    seconds = section_time_limit_seconds(section_type)
    format("%02d:%02d", seconds / 60, seconds % 60)
  end

  def part_totals(section_type)
    PART_TOTALS.fetch(section_type, {})
  end

  def part_total(section_type, part_type)
    part_totals(section_type).fetch(part_type, 0)
  end
end

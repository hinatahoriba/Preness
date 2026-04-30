module Exercises
  class IndexPresenter
    def initialize(exercises:, latest_attempt_by_exercise_id:)
      @exercises = exercises
      @latest_attempt_by_exercise_id = latest_attempt_by_exercise_id
    end

    def section_groups
      grouped_entries.map do |section_type, entries|
        {
          section_type: section_type,
          section_label: ExamCatalog.section_label(section_type),
          parts: build_parts(entries)
        }
      end
    end

    private

    def grouped_entries
      build_entries
        .group_by { |entry| entry[:section_type] }
        .sort_by { |section_type, _entries| Section::SECTION_TYPES.index(section_type) || Section::SECTION_TYPES.length }
    end

    def build_parts(entries)
      entries.group_by { |entry| entry[:part_type] }
        .sort_by { |_part_type, part_entries| part_entries.first[:part_display_order] }
        .map do |part_type, part_entries|
          {
            part_type: part_type,
            part_label: ExamCatalog.part_label(part_type) || "Exercises",
            start_exercise: start_exercise_for(part_entries),
            entries: part_entries.sort_by { |entry| entry[:set_number] }.map { |entry| build_entry_card(entry) }
          }
        end
    end

    def build_entries
      @exercises.filter_map do |exercise|
        section = exercise.sections.first
        part = section&.parts&.first
        question_set = part&.question_sets&.first
        next if section.blank? || part.blank? || question_set.blank?

        attempt = @latest_attempt_by_exercise_id[exercise.id]
        correct_count = attempt ? attempt.answers.count(&:is_correct) : nil

        {
          exercise: exercise,
          section_type: section.section_type,
          section_display_order: section.display_order,
          part_type: part.part_type,
          part_display_order: part.display_order,
          set_number: question_set.display_order,
          attempted: attempt.present?,
          correct_count: correct_count,
          total_count: question_set.questions.size
        }
      end.sort_by do |entry|
        [
          entry[:section_display_order],
          entry[:part_display_order],
          entry[:set_number],
          entry[:exercise].id
        ]
      end
    end

    def build_entry_card(entry)
      attempted = entry[:attempted]
      correct_count = entry[:correct_count]
      total_count = entry[:total_count]

      {
        exercise: entry[:exercise],
        set_number: entry[:set_number],
        attempted: attempted,
        correct_count: correct_count,
        total_count: total_count,
        box_class: box_class_for(attempted: attempted, correct_count: correct_count, total_count: total_count),
        title: exercise_title(entry)
      }
    end

    def exercise_title(entry)
      section_label = ExamCatalog.section_label(entry[:section_type])
      part_label = ExamCatalog.part_label(entry[:part_type])
      set_number = entry[:set_number]

      if part_label.present? && entry[:section_type] != "reading"
        "#{section_label} #{part_label} - Set#{set_number}"
      else
        "#{section_label} - Set#{set_number}"
      end
    end

    def start_exercise_for(part_entries)
      unattempted_entry = part_entries.reject { |entry| entry[:attempted] }.min_by { |entry| entry[:set_number] }
      (unattempted_entry || part_entries.min_by { |entry| entry[:set_number] })[:exercise]
    end

    def box_class_for(attempted:, correct_count:, total_count:)
      return "bg-[#f8f9fa] text-gray-400" unless attempted

      if correct_count == total_count
        "bg-[#f0fdf4] border border-[#bbf7d0] text-[#16a34a]"
      else
        "bg-[#fffcf0] border border-[#fde68a] text-[#d97706]"
      end
    end
  end
end

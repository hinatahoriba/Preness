module Exercises
  class PartSelectionPresenter
    COMBINATIONS = (
      ExamCatalog::PART_TOTALS.flat_map do |section_type, parts|
        parts.keys.map { |part_type| { section_type: section_type, part_type: part_type } }
      end + [{ section_type: "reading", part_type: "passages" }]
    ).freeze

    def initialize; end

    def part_cards
      COMBINATIONS.map do |combo|
        section_type = combo[:section_type]
        part_type    = combo[:part_type]

        {
          section_type: section_type,
          part_type:    part_type,
          label:        card_label(section_type, part_type),
          icon_svg:     icon_svg_for(section_type),
          icon_color:   icon_color_for(section_type),
          icon_bg:      icon_bg_for(section_type)
        }
      end
    end

    private

    def card_label(section_type, part_type)
      section = ExamCatalog.section_label(section_type)
      part    = ExamCatalog.part_label(part_type)
      part.present? ? "#{section} #{part}" : section
    end

    def icon_svg_for(section_type)
      case section_type
      when "listening"
        '<path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 0 1 0 12.728M16.463 8.288a5.25 5.25 0 0 1 0 7.424M6.75 8.25l4.72-4.72a.75.75 0 0 1 1.28.53v15.88a.75.75 0 0 1-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.009 9.009 0 0 1 2.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75Z" />'
      when "structure"
        '<path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />'
      when "reading"
        '<path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />'
      else
        '<path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />'
      end
    end

    def icon_color_for(section_type)
      case section_type
      when "listening" then "text-blue-500"
      when "structure"  then "text-emerald-500"
      when "reading"    then "text-orange-500"
      else "text-slate-500"
      end
    end

    def icon_bg_for(section_type)
      case section_type
      when "listening" then "bg-blue-50"
      when "structure"  then "bg-emerald-50"
      when "reading"    then "bg-orange-50"
      else "bg-slate-50"
      end
    end
  end
end

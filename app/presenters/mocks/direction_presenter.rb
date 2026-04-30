module Mocks
  class DirectionPresenter
    attr_reader :answer_url, :duration_seconds

    def initialize(section:, part:, intro:, answer_url:, duration_seconds:)
      @section = section
      @part = part
      @intro = intro
      @answer_url = answer_url
      @duration_seconds = duration_seconds
    end

    def title
      section_label = ExamCatalog.section_label(@section.section_type).upcase
      part_label = ExamCatalog.part_label(@part.part_type)

      title = "SECTION #{@section.display_order}: #{section_label}"
      title += " - #{part_label.upcase}" if part_label.present?
      title
    end

    def intro_count
      @intro[:count]
    end

    def intro_description
      @intro[:description]
    end

    def initial_timer_display
      format("%02d:%02d", duration_seconds / 60, duration_seconds % 60)
    end
  end
end

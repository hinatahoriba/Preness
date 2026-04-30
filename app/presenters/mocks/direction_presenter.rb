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
      ExamCatalog.section_part_title(
        section_display_order: @section.display_order,
        section_type: @section.section_type,
        part_type: @part.part_type
      )
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

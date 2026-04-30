module Exercises
  class ResultPresenter
    def initialize(correct_count:, total_count:)
      @correct_count = correct_count
      @total_count = total_count
    end

    def score_percent
      return 0 if @total_count.zero?

      ((@correct_count.to_f / @total_count) * 100).round(1)
    end
  end
end

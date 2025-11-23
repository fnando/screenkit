# frozen_string_literal: true

module ScreenKit
  class TimeFormatter
    def self.parse(input)
      return input if input.is_a?(Numeric)

      hour, minute, second = ([0, 0, 0] + input.to_s.split(":"))[-3..-1]
                             .map(&:to_i)

      (hour * 3600) + (minute * 60) + second
    end
  end
end

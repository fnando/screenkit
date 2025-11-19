# frozen_string_literal: true

module ScreenKit
  class Anchor
    # The vertical alignment (:top, :center, :bottom).
    attr_reader :vertical

    # The horizontal alignment (:left, :center, :right).
    attr_reader :horizontal

    def initialize(value)
      @horizontal, @vertical = (Array(value) * 2).take(2)
    end

    def as_json(*)
      [horizontal, vertical]
    end
  end
end

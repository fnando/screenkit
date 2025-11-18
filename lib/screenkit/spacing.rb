# frozen_string_literal: true

module ScreenKit
  class Spacing
    attr_reader :top, :right, :bottom, :left

    def initialize(value)
      @top, @right, @bottom, @left = (Array(value) * 4).take(4)
    end
  end
end

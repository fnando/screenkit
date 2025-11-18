# frozen_string_literal: true

module ScreenKit
  class Watermark
    # The path to the watermark image.
    attr_reader :path

    # The margin spacing for the watermark.
    attr_reader :margin

    # The anchor position for the watermark.
    attr_reader :anchor

    # The opacity of the watermark.
    attr_reader :opacity

    def initialize(value)
      @path = nil
      @margin = Spacing.new(100)
      @anchor = Anchor.new(%w[bottom right])
      @opacity = 0.1

      case value
      when String
        @path = value
      when Hash
        @path = value[:path] if value[:path]
        @margin = Spacing.new(value[:margin]) if value[:margin]
        @anchor = Anchor.new(value[:anchor]) if value[:anchor]
        @opacity = value[:opacity] if value[:opacity]
      end
    end
  end
end

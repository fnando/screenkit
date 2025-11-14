# frozen_string_literal: true

module ScreenKit
  class Callout
    class TextStyle
      attr_reader :color, :size, :font_path

      def initialize(**kwargs)
        kwargs.each do |key, value|
          value = case key.to_sym
                  when :font_path
                    Pathname.new(value)
                  else
                    value
                  end

          instance_variable_set(:"@#{key}", value)
        end
      end

      # Convert hex color (with optional alpha) to RGB + opacity
      # #RRGGBB or #RRGGBBAA
      def rgb_color
        color.match(/#([0-9a-fA-F]{6})/) {|m| m[1] }
      end

      def opacity
        if color.length == 9
          color.match(/#[0-9a-fA-F]{6}([0-9a-fA-F]{2})/) do |m|
            m[1].to_i(16) / 255.0
          end
        else
          1.0
        end
      end
    end
  end
end

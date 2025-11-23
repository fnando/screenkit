# frozen_string_literal: true

require "mini_magick"

module ScreenKit
  class Callout
    module Styles
      class InlineBlock < Base
        extend SchemaValidator

        attr_reader :background_color, :text_style, :body,
                    :output_path, :padding, :text, :width, :source

        def self.schema_path
          ScreenKit.root_dir
                   .join("screenkit/schemas/callout_styles/inline_block.json")
        end

        def initialize(source:, **kwargs) #  rubocop:disable Lint/MissingSuper
          self.class.validate!(kwargs)

          @source = source

          # Set default values
          kwargs = hi_res({
            text_style: {size: 50, color: "#ffffff"}.merge(text_style || {}),
            width: 600,
            padding: [10, 10, 10, 10],
            background_color: "#000000"
          }.merge(kwargs))

          kwargs.each do |key, value|
            value = case key
                    when :padding
                      Spacing.new(value)
                    when :text_style
                      TextStyle.new(source:, **value)
                    else
                      value
                    end

            instance_variable_set(:"@#{key}", value)
          end
        end

        def as_json(*)
          {
            background_color:,
            text_style: text_style.as_json,
            output_path:,
            padding: padding.as_json,
            text:,
            width:
          }
        end

        def render
          padding_x = padding.horizontal
          padding_y = padding.vertical
          content_width = width - padding_x
          lines = if text.include?("\n")
                    text.lines.map(&:strip)
                  else
                    text_wrap(
                      text,
                      max_width: content_width,
                      font_size: text_style.size
                    )
                  end

          line_images = lines.map do |line|
            render_text_image(
              type: "label",
              text: line,
              style: text_style,
              width: content_width
            )
          end

          max_line_width = line_images.map {|_, w, _| w }.max || 0
          height = line_images.sum {|_, _, h| h }

          offset_y = 0
          image_width = max_line_width + padding_x
          image_height = (padding_y * lines.size) + height

          MiniMagick.convert do |image|
            # Create transparent canvas
            image << "-size"
            image << "#{image_width}x#{image_height}"
            image << "xc:none"

            line_images.each do |path, width, height|
              # Draw rectangle background
              image << "-fill"
              image << background_color
              image << "-draw"
              image << "rectangle 0,#{offset_y}," \
                       "#{width + padding_x}," \
                       "#{offset_y + height + padding_y}"

              # Composite line text
              image << path
              image << "-geometry"
              image << "+#{padding.top}+#{offset_y + padding.left}"
              image << "-composite"
              offset_y += padding_y + height
            end

            image << "PNG:#{output_path}"
          end

          output_path
        rescue MiniMagick::Error => error
          retry if error.message.include?("No such file or directory")
          raise
        ensure
          line_images&.each {|(path)| remove_file(path) }
        end
      end
    end
  end
end

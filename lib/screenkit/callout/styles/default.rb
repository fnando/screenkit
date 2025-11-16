# frozen_string_literal: true

require "mini_magick"

module ScreenKit
  class Callout
    module Styles
      class Default < Base
        extend SchemaValidator

        attr_reader :background_color, :body, :body_style,
                    :output_path, :padding, :shadow_color, :shadow_offset,
                    :title, :title_style, :width

        def self.schema_path
          ScreenKit.root_dir.join("screenkit/schemas/callouts/default.json")
        end

        def initialize(**kwargs) #  rubocop:disable Lint/MissingSuper
          self.class.validate!(kwargs)

          # Set default values
          kwargs = hi_res({width: 600, shadow_offset: 20}.merge(kwargs))

          kwargs.each do |key, value|
            value = case key
                    when :body_style, :title_style
                      TextStyle.new(**value)
                    when :padding
                      (Array(value) * 4).take(4)
                    else
                      value
                    end

            instance_variable_set(:"@#{key}", value)
          end
        end

        def render(title:, body:, output_path:)
          title_path, _, title_height =
            *render_text_image(text: title,
                               style: title_style, width: text_width)
          body_path, _, body_height =
            *render_text_image(text: body,
                               style: body_style, width: text_width)
          text_gap = if title_path && body_path
                       (title_style.size * hi_res(0.2)).round
                     else
                       0
                     end

          image_width = width
          image_height = padding[0] +
                         padding[2] +
                         title_height +
                         text_gap +
                         body_height +
                         shadow_offset

          MiniMagick.convert do |image|
            # Create transparent canvas
            image << "-size"
            image << "#{image_width}x#{image_height}"
            image << "xc:none"

            # Draw rectangle shadow
            image << "-fill"
            image << shadow_color
            image << "-draw"
            image << "rectangle 0,#{shadow_offset}," \
                     "#{width - shadow_offset},#{image_height}"

            # Draw rectangle background
            image << "-fill"
            image << background_color
            image << "-draw"
            image << "rectangle #{shadow_offset},0," \
                     "#{image_width},#{image_height - shadow_offset}"

            # Composite title
            if title_path
              image << title_path
              image << "-geometry"
              image << "+#{text_x}+#{padding[0]}"
              image << "-composite"
            end

            # Composite body
            if body_path
              image << body_path
              image << "-geometry"
              image << "+#{text_x}+#{padding[0] + title_height + text_gap}"
              image << "-composite"
            end

            image << "PNG:#{output_path}"
          end

          output_path
        ensure
          remove_file(title_path)
          remove_file(body_path)
        end

        private def text_width = width - padding[1] - padding[3]
        private def text_x = shadow_offset + padding[0]
        private def title_y = padding[0]
        private def body_y = title_y + text_gap + title_style.size
      end
    end
  end
end

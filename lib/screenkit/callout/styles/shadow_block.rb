# frozen_string_literal: true

require "mini_magick"

module ScreenKit
  class Callout
    module Styles
      class ShadowBlock < Base
        extend SchemaValidator

        attr_reader :background_color, :body, :body_style,
                    :output_path, :padding, :shadow,
                    :title, :title_style, :width, :source

        def self.schema_path
          ScreenKit.root_dir
                   .join("screenkit/schemas/callout_styles/shadow_block.json")
        end

        def initialize(source:, **kwargs) #  rubocop:disable Lint/MissingSuper
          self.class.validate!(kwargs)
          @source = source

          # Set default values
          kwargs[:shadow] = case kwargs[:shadow]
                            when false
                              {color: "#ffffffff", offset: 0}
                            when Integer
                              {color: "#00000080", offset: kwargs[:shadow]}
                            when String
                              {color: kwargs[:shadow], offset: 20}
                            else
                              kwargs[:shadow]
                            end

          kwargs = hi_res({width: 600}.merge(kwargs))

          kwargs.each do |key, value|
            value = case key
                    when :body_style, :title_style
                      TextStyle.new(source:, **value)
                    when :padding
                      Spacing.new(value)
                    else
                      value
                    end

            instance_variable_set(:"@#{key}", value)
          end
        end

        def as_json(*)
          {
            background_color:,
            body:,
            body_style: body_style.as_json,
            output_path:,
            padding: padding.as_json,
            shadow:,
            title:,
            title_style: title_style.as_json,
            width:
          }
        end

        def render
          title_path, _, title_height =
            *render_text_image(text: title,
                               style: title_style,
                               width: text_width,
                               type: "caption")
          body_path, _, body_height =
            *render_text_image(text: body,
                               style: body_style,
                               width: text_width,
                               type: "caption")
          text_gap = if title_path && body_path
                       (title_style.size * hi_res(0.2)).round
                     else
                       0
                     end

          image_width = width
          image_height = padding.vertical +
                         title_height +
                         text_gap +
                         body_height +
                         shadow[:offset]

          MiniMagick.convert do |image|
            # Create transparent canvas
            image << "-size"
            image << "#{image_width}x#{image_height}"
            image << "xc:none"

            # Draw rectangle shadow
            image << "-fill"
            image << shadow[:color]
            image << "-draw"
            image << "rectangle 0,#{shadow[:offset]}," \
                     "#{width - shadow[:offset]},#{image_height}"

            # Draw rectangle background
            image << "-fill"
            image << background_color
            image << "-draw"
            image << "rectangle #{shadow[:offset]},0," \
                     "#{image_width},#{image_height - shadow[:offset]}"

            # Composite title
            if title_path
              image << title_path
              image << "-geometry"
              image << "+#{text_x}+#{padding.left}"
              image << "-composite"
            end

            # Composite body
            if body_path
              image << body_path
              image << "-geometry"
              image << "+#{text_x}+#{padding.left + title_height + text_gap}"
              image << "-composite"
            end

            image << "PNG:#{output_path}"
          end

          output_path
        rescue MiniMagick::Error => error
          retry if error.message.include?("No such file or directory")
          raise
        ensure
          remove_file(title_path)
          remove_file(body_path)
        end

        private def text_width = width - padding.horizontal
        private def text_x = shadow[:offset] + padding.left
        private def title_y = padding.top
        private def body_y = title_y + text_gap + title_style.size
      end
    end
  end
end

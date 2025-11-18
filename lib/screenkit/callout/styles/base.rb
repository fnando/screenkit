# frozen_string_literal: true

module ScreenKit
  class Callout
    module Styles
      class Base
        def text_wrap(text, max_width:, font_size:)
          words = text.to_s.split(/\s+/)
          width_factor = 0.6

          [].tap do |lines|
            words.each do |word|
              line = lines.pop.to_s
              word_width = word.size * (font_size * width_factor)
              line_width = line.size * (font_size * width_factor)

              if line_width + word_width <= max_width
                line = [(line unless line.empty?), word].compact.join(" ")
                lines << line
              else
                lines << line
                lines << word
              end
            end
          end
        end

        # Escape text for use in ImageMagick caption.
        def escape_text(text)
          text.gsub("'", "\\\\'")
        end

        def remove_file(path)
          File.unlink(path) if path && File.exist?(path)
        end

        def render_text_image(text:, style:, width:, type:)
          return [nil, 0, 0] if text.to_s.empty?

          image = MiniMagick::Image.open(
            create_text_image(text:, style:, width:, type:)
          )

          [image.path, image.width, image.height]
        end

        # Convert values to high resolution (2x).
        # @param value [Object] The value to convert.
        # @return [Object] The converted value.
        def hi_res(value)
          case value
          when Array
            value.map { hi_res(it) }
          when Hash
            value.transform_values { hi_res(it) }
          when Numeric
            value * 2
          else
            value
          end
        end

        # Create a text image using MiniMagick.
        # @param text [String] The text to render.
        # @param style [TextStyle] The text style to apply.
        # @param width [Integer] The width of the text image.
        # @param type [String] The ImageMagick text type (e.g., "caption").
        # @return [Array] The path to the generated text image, and the actual
        #                 `Tempfile` instance.
        def create_text_image(text:, style:, width:, type:)
          hash = SecureRandom.hex(10)
          tmp_path = File.join(Dir.tmpdir, "callout-text-#{hash}.png")
          FileUtils.mkdir_p(File.dirname(tmp_path))

          MiniMagick.convert do |image|
            unless type == "label"
              image << "-size"
              image << "#{width}x"
            end

            image << "-background"
            image << "none"
            image << "-fill"
            image << style.color
            image << "-font"
            image << style.font_path.to_s
            image << "-pointsize"
            image << style.size.to_s
            image << "#{type}:#{escape_text(text)}"
            image << "PNG:#{tmp_path}"
          end

          tmp_path
        rescue MiniMagick::Error => error
          retry if error.message.include?("No such file or directory")
          raise
        end
      end
    end
  end
end

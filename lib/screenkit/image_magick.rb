# frozen_string_literal: true

module ScreenKit
  module ImageMagick
    # Wrap text to fit within the specified maximum width.
    # @param text [String] The text to wrap.
    # @param max_width [Integer] The maximum width in pixels.
    # @param font_size [Integer] The font size in points.
    # @return [Array<String>] The wrapped lines of text.
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
    def escape_text_for_image(text)
      text.gsub("'", "\\\\'")
    end

    # Render text into an image using MiniMagick.
    # @param text [String] The text to render.
    # @param style [TextStyle] The text style to apply.
    # @param width [Integer] The width of the text image.
    # @param type [String] The ImageMagick text type (e.g., "caption").
    # @param path [String, nil] The output path.
    # @return [Array] The path to the generated text image, width, and
    # height.
    def render_text_image(text:, style:, width:, type:, path: nil)
      return [nil, 0, 0] if text.to_s.empty?

      image = MiniMagick::Image.open(
        create_text_image(text:, style:, width:, type:, path:)
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
    # @param path [String, nil] The output path.
    # @return [Array] The path to the generated text image, and the actual
    #                 `Tempfile` instance.
    def create_text_image(text:, style:, width:, type:, path: nil)
      path ||= File.join(Dir.tmpdir, "callout-text-#{SecureRandom.hex(10)}.png")
      FileUtils.mkdir_p(File.dirname(path))

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
        image << "#{type}:#{escape_text_for_image(text)}"
        image << "PNG:#{path}"
      end

      path
    rescue MiniMagick::Error => error
      retry if error.message.include?("No such file or directory")
      raise
    end
  end
end

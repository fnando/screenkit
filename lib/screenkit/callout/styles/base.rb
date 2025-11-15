# frozen_string_literal: true

module ScreenKit
  class Callout
    module Styles
      class Base
        # Escape text for use in ImageMagick caption.
        private def escape_text(text)
          text.gsub("'", "\\\\'")
        end

        private def remove_file(path)
          File.unlink(path) if path && File.exist?(path)
        end

        private def render_text_image(text:, style:, width:)
          return [nil, 0, 0] if text.to_s.empty?

          image = MiniMagick::Image.open(
            create_text_image(text:, style:, width:)
          )

          [image.path, image.width, image.height]
        end

        # Create a text image using MiniMagick.
        # @param text [String] The text to render.
        # @param style [TextStyle] The text style to apply.
        # @param width [Integer] The width of the text image.
        # @return [Array] The path to the generated text image, and the actual
        #                 `Tempfile` instance.
        private def create_text_image(text:, style:, width:)
          hash = SecureRandom.hex(10)
          tmp_path = File.join(Dir.tmpdir, "callout-text-#{hash}.png")
          FileUtils.mkdir_p(File.dirname(tmp_path))

          MiniMagick.convert do |image|
            image << "-size"
            image << "#{width}x"
            image << "-background"
            image << "none"
            image << "-fill"
            image << style.color
            image << "-font"
            image << style.font_path.to_s
            image << "-pointsize"
            image << style.size.to_s
            image << "caption:#{escape_text(text)}"
            image << "PNG:#{tmp_path}"
          end

          tmp_path
        end
      end
    end
  end
end

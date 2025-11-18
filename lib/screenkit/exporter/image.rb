# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Image
      include Shell

      attr_reader :image_path

      def initialize(image_path:)
        @image_path = image_path
      end

      def export(output_path)
        cmd = [
          "ffmpeg",
          "-i", image_path,
          "-vf", "scale=1920:1080:force_original_aspect_ratio=decrease," \
                 "pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black",
          "-r", 24,
          "-c:v", "libx264", "-crf", "0", "-pix_fmt", "yuv444p",
          "-y",
          output_path
        ]

        run_command(*cmd)
      end
    end
  end
end

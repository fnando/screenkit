# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Video
      include Shell
      extend Utils

      # The path to the input video file.
      attr_reader :input_path

      # The path to the log file.
      attr_reader :log_path

      def initialize(input_path:, log_path: nil)
        @input_path = input_path
        @log_path = log_path
      end

      def self.right_fps?(path)
        (-0.02..0.02).cover?(24 - fps(path))
      end

      def export(output_path)
        if self.class.right_fps?(input_path)
          FileUtils.cp(input_path, output_path)
          return
        end

        run_command "ffmpeg",
                    "-i", input_path,
                    "-r", "24",
                    "-c:v", "libx264",
                    "-y",
                    output_path,
                    log_path:
      end
    end
  end
end

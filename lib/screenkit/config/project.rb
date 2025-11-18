# frozen_string_literal: true

module ScreenKit
  module Config
    class Project < Base
      # The directory where episode source files are stored.
      attr_reader :episode_dir

      # The directory where resources files are stored.
      attr_reader :resources_dir

      # The output directory for exported files.
      attr_reader :output_dir

      # Callout configurations
      attr_reader :callouts

      # Scene configurations
      attr_reader :scenes

      # TTS configuration
      attr_reader :tts

      # The backtrack music configuration.
      attr_reader :backtrack

      # The watermark configuration.
      attr_reader :watermark

      def self.schema_path
        @schema_path ||=
          ScreenKit.root_dir.join("screenkit/schemas/project.json")
      end

      private def process(key, value)
        case key.to_sym
        when :resources_dir
          Array(value)
        when /_(dir|path)$/
          Pathname(value)
        else
          value
        end
      end
    end
  end
end

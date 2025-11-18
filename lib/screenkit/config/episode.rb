# frozen_string_literal: true

module ScreenKit
  module Config
    class Episode < Base
      # The scenes configuration for the episode.
      attr_reader :scenes

      # The title of the episode.
      attr_reader :title

      # The episode's TTS engine configuration.
      attr_reader :tts

      # The episode's backtrack music configuration.
      attr_reader :backtrack

      def self.schema_path
        @schema_path ||=
          ScreenKit.root_dir.join("screenkit/schemas/episode.json")
      end

      def initialize(**)
        @scenes = {}

        super
      end

      def process(key, value)
        case key.to_sym
        when /_(dir|path)$/
          Pathname(value)
        else
          value
        end
      end
    end
  end
end

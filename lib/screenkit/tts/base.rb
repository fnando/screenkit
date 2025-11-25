# frozen_string_literal: true

module ScreenKit
  module TTS
    class Base
      extend SchemaValidator

      using CoreExt

      # Additional options for the tts engine.
      attr_reader :options

      # The preset name for the tts engine.
      attr_reader :id

      # The list of segments.
      # This is available so that engines can contextually generate audio, for
      # instance, by providing previous/next text (e.g. Eleven Labs).
      attr_reader :segments

      # The API key for the tts engine, if applicable.
      attr_reader :api_key

      # Detects if the tts engine is available.
      def self.available?(**)
        false
      end

      def self.engine_name
        name.split("::").last.underscore
      end

      def initialize(id: nil, segments: nil, api_key: nil, **options)
        @segments = Array(segments)
        @options = options
        @id = id
        @api_key = api_key
      end

      def redact_file(path, text)
        return unless File.file?(path)

        content = File.read(path).gsub(text, "[REDACTED]")
        File.write(path, content)
      end
    end
  end
end

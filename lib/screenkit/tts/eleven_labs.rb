# frozen_string_literal: true

module ScreenKit
  module VoiceEngines
    class TTS
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir
                 .join("screenkit/schemas/tts/elevenlabs.json")
      end

      # The Eleven Labs API key.
      attr_reader :api_key

      # Additional options for the Eleven Labs voice engine.
      attr_reader :options

      def initialize(api_key:, **options)
        @api_key = api_key
        @options = options
      end

      def generate(output_path:, text:)
        self.class.validate!(options)
        voice_id = options.delete(:voice_id)

        require "aitch"

        response = Aitch.post(
          url: "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}",
          body: JSON.dump(options.merge(text:)),
          headers: {
            "content-type": "application/json",
            "user-agent": "ScreenKit/#{ScreenKit::VERSION}",
            "xi-api-key": api_key
          }
        )

        File.binwrite(output_path, response.body)
      end
    end
  end
end

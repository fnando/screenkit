# frozen_string_literal: true

module ScreenKit
  module TTS
    class ElevenLabs < Base
      def self.schema_path
        ScreenKit.root_dir
                 .join("screenkit/schemas/tts/elevenlabs.json")
      end

      # The Eleven Labs API key.
      attr_reader :api_key

      def initialize(api_key:, **)
        super(**)
        @api_key = api_key
      end

      def available?
        enabled? && !api_key.to_s.empty?
      end

      def generate(output_path:, text:, log_path: nil)
        self.class.validate!(options)
        voice_id = options.delete(:voice_id)

        if log_path
          File.open(log_path, "w") do |f|
            f << JSON.pretty_generate(options.merge(text:))
          end
        end

        require "aitch"

        response = Aitch.post(
          url: "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}",
          body: JSON.dump(options.merge(text:)),
          options: {expect: 200},
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

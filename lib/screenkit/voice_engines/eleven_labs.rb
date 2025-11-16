# frozen_string_literal: true

module ScreenKit
  module VoiceEngines
    class ElevenLabs
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir
                 .join("screenkit/schemas/voice_engines/elevenlabs.json")
      end

      def self.generate_voiceover(output_path:, api_key:, **params)
        validate!(params)
        voice_id = params.delete(:voice_id)

        require "aitch"

        response = Aitch.post(
          url: "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}",
          body: JSON.dump(params),
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

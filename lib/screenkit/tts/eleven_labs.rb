# frozen_string_literal: true

module ScreenKit
  module TTS
    class ElevenLabs < Base
      include HTTP

      def self.schema_path
        ScreenKit.root_dir
                 .join("screenkit/schemas/tts/elevenlabs.json")
      end

      def self.available?(api_key: nil, **)
        api_key.to_s.start_with?(api_key_prefix)
      end

      def all_texts
        @all_texts ||= segments.map(&:script_content)
      end

      def generate(output_path:, text:, log_path: nil)
        voice_id = options[:voice_id]

        current_index = all_texts.index { it == text }

        if current_index
          previous_text = all_texts[current_index - 1]
          next_text = all_texts[current_index + 1]
        end

        params = options.merge(text:, previous_text:, next_text:)
                        .except(:voice_id)

        response = json_post(
          url: "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}",
          params:,
          headers: {"xi-api-key": api_key},
          api_key:,
          log_path:
        )

        File.binwrite(output_path, response.body)
      end
    end
  end
end

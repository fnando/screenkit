# frozen_string_literal: true

module ScreenKit
  module TTS
    class ElevenLabs < Base
      def self.schema_path
        ScreenKit.root_dir
                 .join("screenkit/schemas/tts/elevenlabs.json")
      end

      def self.available?(api_key: nil, **)
        api_key.to_s.empty?
      end

      def all_texts
        @all_texts ||= segments.map(&:script_content)
      end

      def generate(output_path:, text:, log_path: nil)
        voice_id = options[:voice_id]

        if log_path
          File.open(log_path, "w") do |f|
            f << JSON.pretty_generate(options.merge(text:))
          end
        end

        require "aitch"

        Aitch.configure do |config|
          config.logger = Logger.new(log_path) if log_path
        end

        current_index = all_texts.index { it == text }

        if current_index
          previous_text = all_texts[current_index - 1]
          next_text = all_texts[current_index + 1]
        end

        params = options.merge(text:, previous_text:, next_text:)
                        .except(:voice_id)

        response = Aitch.post(
          url: "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}",
          body: JSON.dump(params),
          options: {expect: 200},
          headers: {
            "content-type": "application/json",
            "user-agent": "ScreenKit/#{ScreenKit::VERSION}",
            "xi-api-key": api_key
          }
        )

        File.binwrite(output_path, response.body)
      ensure
        redact_file(log_path, api_key)
      end
    end
  end
end

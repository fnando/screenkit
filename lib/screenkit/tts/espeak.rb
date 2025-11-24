# frozen_string_literal: true

module ScreenKit
  module TTS
    class Espeak < Base
      include Shell

      def self.schema_path
        ScreenKit.root_dir.join("screenkit/schemas/tts/espeak.json")
      end

      def available?
        enabled? && command_exist?("espeak")
      end

      def generate(text:, output_path:, log_path: nil)
        self.class.validate!(options)

        {voice: nil, rate: nil}.merge(options) => {voice:, rate:}

        run_command "espeak",
                    (["-v", voice] if voice),
                    (["-s", rate] if rate),
                    "-w", output_path.sub_ext(".wav"),
                    text,
                    log_path:
      end
    end
  end
end

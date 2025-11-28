# frozen_string_literal: true

module ScreenKit
  module TTS
    class Espeak < Base
      extend Shell

      def self.available?(**)
        command_exist?("espeak")
      end

      def self.schema_path
        ScreenKit.root_dir.join("schemas/tts/espeak.json")
      end

      def generate(text:, output_path:, log_path: nil)
        self.class.validate!(options)

        {voice: nil, rate: nil}.merge(options) => {voice:, rate:}

        self.class.run_command "espeak",
                               (["-v", voice] if voice),
                               (["-s", rate] if rate),
                               "-w", output_path.sub_ext(".wav"),
                               text,
                               log_path:
      end
    end
  end
end

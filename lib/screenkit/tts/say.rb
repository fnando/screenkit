# frozen_string_literal: true

module ScreenKit
  module TTS
    class Say < Base
      extend Shell

      def self.schema_path
        ScreenKit.root_dir.join("schemas/tts/say.json")
      end

      def self.available?(**)
        command_exist?("say")
      end

      def generate(text:, output_path:, log_path: nil)
        self.class.validate!(options)

        {voice: nil, rate: nil}.merge(options) => {voice:, rate:}

        self.class.run_command "say",
                               (["-v", voice] if voice),
                               (["-r", rate] if rate),
                               "-o", output_path.sub_ext(".aiff"),
                               text,
                               log_path:
      end
    end
  end
end

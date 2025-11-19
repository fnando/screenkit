# frozen_string_literal: true

module ScreenKit
  module TTS
    class Say
      include Shell
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("screenkit/schemas/tts/say.json")
      end

      def initialize(**options)
        @options = options
      end

      def generate(text:, output_path:, log_path: nil)
        self.class.validate!(@options)

        {voice: nil, rate: nil}.merge(@options) => {voice:, rate:}

        run_command "say",
                    (["-v", voice] if voice),
                    (["-r", rate] if rate),
                    "-o", output_path.sub_ext(".aiff"),
                    text,
                    log_path:
      end
    end
  end
end

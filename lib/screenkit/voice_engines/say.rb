# frozen_string_literal: true

module ScreenKit
  module VoiceEngines
    class Say
      extend Shell
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("screenkit/schemas/voice_engines/say.json")
      end

      def self.generate_voiceover(text:, output_path:, **options)
        validate!(options)

        {voice: nil, rate: nil}.merge(options) => {voice:, rate:}

        run_command "say",
                    (["-v", voice] if voice),
                    (["-r", rate] if rate),
                    "-o", output_path,
                    "--file-format", "m4af",
                    text
      end
    end
  end
end

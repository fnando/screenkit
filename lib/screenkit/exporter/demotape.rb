# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Demotape
      include Shell

      attr_reader :demotape_path

      def initialize(demotape_path:)
        @demotape_path = demotape_path
      end

      def export(output_path)
        run_command "demotape",
                    "run",
                    demotape_path,
                    "--fps", 24,
                    "--overwrite",
                    "--output-path", output_path
      end
    end
  end
end

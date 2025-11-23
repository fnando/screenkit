# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Demotape
      include Shell

      DURATION_ATTRIBUTES = %w[
        typing_speed loop_delay run_enter_delay run_sleep
      ].freeze

      attr_reader :demotape_path, :log_path, :options

      def initialize(demotape_path:, options: {}, log_path: nil)
        @demotape_path = demotape_path
        @log_path = log_path
        @options = options
      end

      def export(output_path)
        run_command "demotape",
                    "run",
                    demotape_path,
                    options_to_args(options),
                    "--width", 1920,
                    "--height", 1080,
                    "--fps", 24,
                    "--overwrite",
                    "--output-path", output_path,
                    log_path:
      end

      def options_to_args(options)
        (options || {}).flat_map do |key, value|
          if DURATION_ATTRIBUTES.include?(key.to_s)
            value = Duration.parse(value)
          end

          [key.to_s.tr("_", "-").prepend("--"), value]
        end
      end
    end
  end
end

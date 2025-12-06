# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Playwright
      include Shell

      attr_reader :script_path, :log_path, :options

      def initialize(script_path:, options: {}, log_path: nil)
        @script_path = script_path
        @log_path = log_path
        @options = options
      end

      def export(output_path)
        run_command "playwright-video",
                    "export",
                    script_path,
                    options_to_args(options),
                    "--output-path", output_path,
                    log_path:,
                    chdir: script_path.parent.parent
      end

      def options_to_args(options)
        (options || {}).flat_map do |key, value|
          [key.to_s.tr("_", "-").prepend("--"), value]
        end
      end
    end
  end
end

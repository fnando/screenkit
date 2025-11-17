# frozen_string_literal: true

module ScreenKit
  module CLI
    class Base < Thor
      check_unknown_options!

      class_option :config,
                   type: :string,
                   default: "screenkit.yml",
                   desc: "Path to config file"

      def self.exit_on_failure?
        true
      end

      no_commands do
        def config
          @config ||= Config::Project.load_file(options.config)
        end
      end
    end
  end
end

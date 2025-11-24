# frozen_string_literal: true

module ScreenKit
  module CLI
    class Root < Base
      desc "episode SUBCOMMAND", "Episode commands"
      subcommand "episode", CLI::Episode

      desc "new PATH", "Create a new project"
      def new(path)
        generator = Generators::Project.new
        generator.destination_root = path
        generator.options = options
        generator.invoke_all
      end

      desc "callout", "Generate a callout PNG"
      option :type,
             type: :string,
             required: true,
             desc: "Callout type (e.g., info, warning)"
      option :title,
             type: :string,
             required: true,
             desc: "Callout title text"
      option :body,
             type: :string,
             required: true,
             desc: "Callout body text"
      option :output,
             type: :string,
             desc: "Output path for PNG"
      def callout
        callout = config.callouts[options.type.to_sym]

        unless callout
          say "Callout type '#{options[:type]}' not found in config", :red
          exit 1
        end

        output_path = options[:output]
        output_path ||= Pathname(Tempfile.create(["callout-", ".png"]).path)

        callout.render(
          output_path:,
          title: options.title,
          body: options.body
        )

        puts output_path
      end

      desc "completion", "Generate shell completion script"
      option :shell,
             type: :string,
             required: true,
             enum: %w[bash zsh powershell fish]
      def completion
        puts Thor::Completion.generate(
          name: "screenkit",
          description: "Terminal to screencast, simplified",
          version: VERSION,
          cli: self.class,
          shell: options.shell
        )
      end

      no_commands do
        # Add helper methods here
      end
    end
  end
end

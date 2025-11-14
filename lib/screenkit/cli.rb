# frozen_string_literal: true

module ScreenKit
  class CLI < Thor
    check_unknown_options!

    def self.exit_on_failure?
      true
    end

    desc "new PATH", "Create a new project"
    def new(path)
      generator = Generators::Project.new
      generator.destination_root = File.expand_path(path)
      generator.options = options
      generator.invoke_all
    end

    desc "callout", "Generate a callout PNG"
    option :config,
           type: :string,
           default: "screenkit.yml",
           desc: "Path to config file"
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
      config = Project::Config.load_file(options.config)
      callout = config.callouts[options.type.to_sym]

      unless callout
        say "Callout type '#{options[:type]}' not found in config", :red
        exit 1
      end

      output_path = options[:output]
      output_path ||= Pathname.new(Tempfile.create(["callout-", ".png"]).path)

      callout.render(
        output_path:,
        title: options.title,
        body: options.body
      )

      puts output_path
    end

    no_commands do
      # Add helper methods here
    end
  end
end

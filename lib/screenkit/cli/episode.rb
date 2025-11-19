# frozen_string_literal: true

module ScreenKit
  module CLI
    class Episode < Base
      namespace :episode
      using CoreExt

      desc "new", "Create a new episode"
      option :title,
             type: :string,
             required: true,
             desc: "Title of the episode"
      def new
        options = self.options.dup
        episode_number = config.episode_dir.parent.glob("*").count(&:directory?)

        dir = format(
          config.episode_dir.basename.to_s,
          episode_number: episode_number + 1,
          episode_slug: options.title.dasherize,
          date: Time.now.strftime("%Y-%m-%d")
        )
        options[:episode_dir] = config.episode_dir.parent.join(dir)

        generator = Generators::Episode.new
        generator.destination_root =
          File.expand_path(File.dirname(options.config))
        generator.options = options
        generator.invoke_all
      end

      desc "export", "Export episode into a final video file"
      option :dir,
             type: :string,
             required: true,
             desc: "Directory of the episode to export"
      option :voice_api_key,
             type: :string,
             desc: "API key for the voice synthesis service"
      option :overwrite,
             type: :boolean,
             default: false,
             desc: "Overwrite existing exported file"
      option :match_segment,
             type: :string,
             desc: "Only export segments matching this string"
      option :output_dir,
             type: :string,
             desc: "Path to save the exported video files"
      option :banner,
             type: :boolean,
             default: true,
             desc: "Display the ScreenKit banner"
      option :require,
             type: :array,
             default: [],
             desc: "Additional Ruby files to require"
      def export
        puts Banner.banner if options.banner

        episode_config = Config::Episode.load_file(
          File.join(options.dir, "config.yml")
        )

        options.require.each { require(it) }

        exporter = ScreenKit::Exporter::Episode.new(
          project_config: config,
          config: episode_config,
          options:
        )

        exporter.export
      end
    end
  end
end

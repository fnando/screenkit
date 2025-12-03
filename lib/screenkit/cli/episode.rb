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
        generator.destination_root = File.dirname(options.config)
        generator.options = options
        generator.invoke_all
      end

      desc "export", "Export episode into a final video file"
      option :dir,
             type: :string,
             required: true,
             desc: "Directory of the episode to export"
      option :tts_api_key,
             type: :string,
             desc: "API key for the voice synthesis service"
      option :overwrite,
             type: :boolean,
             default: false,
             desc: "Overwrite existing exported file"
      option :overwrite_voiceover,
             type: :boolean,
             default: false,
             desc: "Regenerate all voiceover audio files"
      option :overwrite_content,
             type: :boolean,
             default: false,
             desc: "Regenerate all content files (e.g., demo tapes)"
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
      option :tts_preset,
             type: :string,
             desc: "Preset voice configuration for TTS"
      def export
        puts Banner.banner if options.banner

        project_config = if File.file?(options.config)
                           Config.load_yaml_file(options.config)
                         else
                           {}
                         end

        episode_config = File.join(options.dir, "config.yml")
        episode_config = if File.file?(episode_config)
                           Config.load_yaml_file(episode_config)
                         else
                           {}
                         end

        options.require.each { require(it) }

        # Ensure overwrite is only set if other individual options aren't set.
        options[:overwrite] = options.overwrite &&
                              !options.overwrite_content &&
                              !options.overwrite_voiceover

        exporter = ScreenKit::Exporter::Episode.new(
          config: Config.load(**project_config.deep_merge(**episode_config)),
          options:
        )

        exporter.export
      end
    end
  end
end

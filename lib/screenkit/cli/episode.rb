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
        options.dup
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
    end
  end
end

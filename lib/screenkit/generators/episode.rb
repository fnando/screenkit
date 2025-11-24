# frozen_string_literal: true

module ScreenKit
  module Generators
    class Episode < Thor::Group
      include Thor::Actions

      attr_accessor :options

      def self.exit_on_failure?
        true
      end

      def self.source_root
        File.join(__dir__, "episode")
      end

      def setup_episode_dir
        template "config.yml.erb", options.episode_dir.join("config.yml")
        directory "scripts", options.episode_dir.join("scripts")
        directory "content", options.episode_dir.join("content")
        empty_directory resources_dir
        empty_directory voiceovers_dir
        create_file resources_dir.join(".keep")
        create_file voiceovers_dir.join(".keep")
      end

      no_commands do
        # Add helper methods here
        def resources_dir = options.episode_dir.join("resources")
        def voiceovers_dir = options.episode_dir.join("voiceovers")
      end
    end
  end
end

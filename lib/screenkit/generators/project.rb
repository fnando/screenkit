# frozen_string_literal: true

module ScreenKit
  module Generators
    class Project < Thor::Group
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "project")
      end

      def create_project_dir
        template "Gemfile.erb", "Gemfile"
      end

      def copy_files
        copy_file "screenkit.yml"
        directory "resources", exclude_pattern: /DS_Store/
        directory ".github", exclude_pattern: /DS_Store/
      end

      def bundle_install
        return unless options.bundler

        in_root do
          run "bundle install"
        end
      end

      no_commands do
        # Add helper methods here
      end
    end
  end
end

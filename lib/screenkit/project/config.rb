# frozen_string_literal: true

module ScreenKit
  module Project
    class Config
      extend SchemaValidator

      # The directory where episode source files are stored.
      attr_reader :episode_dir

      # The directory where sound effect files are stored.
      attr_reader :sounds_dir

      # The directory where backtrack music files are stored.
      attr_reader :backtracks_dir

      # Callout configurations
      attr_reader :callouts

      # Scene configurations
      attr_reader :scenes

      def self.schema_path
        @schema_path ||=
          ScreenKit.root_dir.join("screenkit/schemas/project.json")
      end

      def self.load_file(path)
        unless File.file?(path)
          raise FileNotFoundError, "Config file not found: #{path}"
        end

        config = YAML.load_file(path, symbolize_names: true)
        load(config)
      end

      def self.load(config)
        validate!(config)

        new(**config)
      end

      def initialize(**kwargs)
        kwargs.each do |key, value|
          value = process(key, value)
          instance_variable_set(:"@#{key}", value)
        end
      end

      private def process(key, value)
        case key.to_sym
        when /_(dir|path)$/
          Pathname.new(value)
        when :callouts
          value.transform_values { Callout.new(**it) }
        else
          value
        end
      end
    end
  end
end

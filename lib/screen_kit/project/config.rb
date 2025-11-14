# frozen_string_literal: true

module ScreenKit
  module Project
    class Config
      # The directory where episode files are stored
      attr_reader :episodes_dir

      # The path to the logo file
      attr_reader :logo_path

      def self.schema
        @schema ||= YAML.load_file(
          File.join(__dir__, "../schemas/project.json")
        )
      end

      def self.load_file(path)
        config = YAML.load_file(path)
        load(config)
      end

      def self.load(config)
        errors = JSON::Validator.fully_validate(schema, config)

        return new(**config) if errors.empty?

        raise InvalidConfigSchemaError, errors.first
      end

      def initialize(**kwargs)
        kwargs.each do |key, value|
          value = process(key, value)
          instance_variable_set(:"@#{key}", value)
        end
      end

      private def process(key, value)
        case key
        when /_(dir|path)$/
          Pathname.new(value)
        else
          value
        end
      end
    end
  end
end

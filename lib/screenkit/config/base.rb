# frozen_string_literal: true

module ScreenKit
  module Config
    class Base
      extend SchemaValidator

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

      def process(_key, value)
        value
      end
    end
  end
end

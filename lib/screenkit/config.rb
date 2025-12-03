# frozen_string_literal: true

module ScreenKit
  class Config
    using CoreExt
    extend SchemaValidator

    # The episode title.
    attr_reader :title

    # The directory where episode source files are stored.
    attr_reader :episode_dir

    # The directory where resources files are stored.
    attr_reader :resources_dir

    # The output directory for exported files.
    attr_reader :output_dir

    # Callout styles
    attr_reader :callout_styles

    # Scene configurations
    attr_reader :scenes

    # TTS configuration
    attr_reader :tts

    # The backtrack music configuration.
    attr_reader :backtrack

    # The watermark configuration.
    attr_reader :watermark

    # The demotape configuration.
    attr_reader :demotape

    def self.schema_path
      @schema_path ||=
        ScreenKit.root_dir.join("schemas/config.json")
    end

    def self.load_yaml_file(path)
      unless File.file?(path)
        raise FileNotFoundError, "Config file not found: #{path}"
      end

      template = File.read(path)
      contents = ERB.new(template).result

      YAML.load(contents, symbolize_names: true)
    end

    def self.load_file(path)
      load(load_yaml_file(path))
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

    def to_h
      instance_variables.each_with_object({}) do |var, hash|
        key = var.to_s.delete_prefix("@").to_sym
        hash[key] = instance_variable_get(var).as_json
      end
    end

    def process(key, value)
      case key.to_sym
      when :resources_dir
        Array(value)
      when /_(dir|path)$/
        Pathname(value)
      else
        value
      end
    end
  end
end

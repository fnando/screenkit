# frozen_string_literal: true

require "thor"
require "yaml"
require "json-schema"
require "mini_magick"
require "pathname"

module ScreenKit
  require_relative "screenkit/version"
  require_relative "screenkit/core_ext/string"
  require_relative "screenkit/shell"
  require_relative "screenkit/schema_validator"
  require_relative "screenkit/generators/project"
  require_relative "screenkit/generators/episode"
  require_relative "screenkit/project/config"
  require_relative "screenkit/callout"
  require_relative "screenkit/callout/text_style"
  require_relative "screenkit/transition"
  require_relative "screenkit/callout/styles/base"
  require_relative "screenkit/callout/styles/default"
  require_relative "screenkit/cli"
  require_relative "screenkit/cli/base"
  require_relative "screenkit/cli/episode"
  require_relative "screenkit/cli/root"
  require_relative "screenkit/voice_engines/say"
  require_relative "screenkit/voice_engines/eleven_labs"
  require_relative "screenkit/exporter/intro"
  require_relative "screenkit/exporter/outro"
  require_relative "screenkit/exporter/demotape"

  def self.root_dir
    @root_dir ||= Pathname.new(__dir__)
  end

  # Raised when the configuration schema is invalid.
  InvalidConfigSchemaError = Class.new(StandardError)

  # Raised when a file is not found.
  FileNotFoundError = Class.new(StandardError)

  require_files = lambda do |pattern|
    Gem.find_files_from_load_path(pattern).each do |path|
      next if path.include?("test")

      require(path)
    end
  end

  # Load all files that may be available as plugins.
  require_files.call("screenkit/callout/styles/*.rb")
  require_files.call("screenkit/callout/voice_engines/*.rb")
end

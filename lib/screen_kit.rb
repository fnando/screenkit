# frozen_string_literal: true

require "thor"
require "yaml"
require "json-schema"

module ScreenKit
  require_relative "screen_kit/version"
  require_relative "screen_kit/generators/project"
  require_relative "screen_kit/project/config"

  # Raised when the configuration schema is invalid.
  InvalidConfigSchemaError = Class.new(StandardError)
end

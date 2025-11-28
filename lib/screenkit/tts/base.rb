# frozen_string_literal: true

require "json-schema"
require "aitch"
require "logger"

module ScreenKit
  module TTS
    class Base
      require_relative "../schema_validator"
      require_relative "../shell"
      require_relative "../http"
      require_relative "../core_ext"
      require_relative "../version"

      extend SchemaValidator
      extend Shell
      include HTTP

      using CoreExt

      # Additional options for the tts engine.
      attr_reader :options

      # The preset name for the tts engine.
      attr_reader :id

      # The list of segments.
      # This is available so that engines can contextually generate audio, for
      # instance, by providing previous/next text (e.g. Eleven Labs).
      attr_reader :segments

      # The API key for the tts engine, if applicable.
      attr_reader :api_key

      # Detects if the tts engine is available.
      def self.available?(**)
        false
      end

      def self.engine_name
        name.split("::").last.underscore
      end

      def self.api_key_prefix
        "#{engine_name}:"
      end

      def initialize(id: nil, segments: nil, api_key: nil, **options)
        @segments = Array(segments)
        @options = options
        @id = id

        return unless api_key

        @api_key = api_key.delete_prefix("#{self.class.engine_name}:")
      end
    end
  end
end

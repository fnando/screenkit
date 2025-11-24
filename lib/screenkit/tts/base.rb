# frozen_string_literal: true

module ScreenKit
  module TTS
    class Base
      extend SchemaValidator

      # Additional options for the tts engine.
      attr_reader :options

      def initialize(enabled: true, **options)
        @enabled = enabled
        @options = options
      end

      def enabled?
        @enabled
      end
    end
  end
end

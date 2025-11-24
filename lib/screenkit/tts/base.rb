# frozen_string_literal: true

module ScreenKit
  module TTS
    class Base
      extend SchemaValidator

      # Additional options for the tts engine.
      attr_reader :options

      # The preset name for the tts engine.
      attr_reader :id

      def initialize(id: nil, enabled: true, **options)
        @enabled = enabled
        @options = options
        @id = id
      end

      def enabled?
        @enabled
      end
    end
  end
end

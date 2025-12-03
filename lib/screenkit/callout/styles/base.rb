# frozen_string_literal: true

module ScreenKit
  class Callout
    module Styles
      class Base
        require_relative "../../schema_validator"

        attr_reader :source, :output_path, :log_path
        attr_accessor :options

        extend SchemaValidator
        include ImageMagick

        def initialize(source:, output_path:, log_path: nil, **options)
          @source = source
          @output_path = output_path
          @log_path = log_path
          @options = options
        end

        # Remove a file if it exists.
        # @param path [String] The file path to remove.
        def remove_file(path)
          File.unlink(path) if path && File.exist?(path)
        end
      end
    end
  end
end

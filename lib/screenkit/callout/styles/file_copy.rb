# frozen_string_literal: true

module ScreenKit
  class Callout
    module Styles
      class FileCopy
        attr_reader :output_path, :file_path, :source

        extend SchemaValidator

        def self.schema_path
          ScreenKit.root_dir
                   .join("screenkit/schemas/callout_styles/file_copy.json")
        end

        def initialize(source:, **kwargs)
          self.class.validate!(kwargs)
          @source = source
          @file_path = kwargs[:file_path]
          @output_path = kwargs[:output_path]
        end

        def render
          FileUtils.mkdir_p(File.dirname(output_path))
          FileUtils.cp source.search(file_path), output_path
        end
      end
    end
  end
end

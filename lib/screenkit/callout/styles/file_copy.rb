# frozen_string_literal: true

module ScreenKit
  class Callout
    module Styles
      class FileCopy < Base
        def self.schema_path
          ScreenKit.root_dir.join("schemas/callout_styles/file_copy.json")
        end

        def initialize(source:, **kwargs)
          self.class.validate!(kwargs)
          super
        end

        def render
          ext = File.extname(options[:file_path])
          FileUtils.mkdir_p(File.dirname(output_path))
          FileUtils.cp source.search(options[:file_path]),
                       output_path.sub_ext(ext)
        end
      end
    end
  end
end

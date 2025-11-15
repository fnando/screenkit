# frozen_string_literal: true

module ScreenKit
  module CoreExt
    refine String do
      def dasherize
        dup
          .unicode_normalize(:nfkd)
          .gsub(/[^\x00-\x7F]/, "")
          .gsub(/[^-\w]+/xim, "-")
          .gsub(/-+/xm, "-")
          .gsub!(/^-?(.*?)-?$/, '\1')
          .downcase
      end
    end
  end
end

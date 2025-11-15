# frozen_string_literal: true

module ScreenKit
  module CoreExt
    refine String do
      def dasherize
        unicode_normalize(:nfkd)
          .delete("'")
          .gsub(/[^\x00-\x7F]/, "")
          .gsub(/[^-\w]+/xim, "-")
          .tr("_", "-")
          .gsub(/-+/xm, "-")
          .gsub(/^-?(.*?)-?$/, '\1')
          .downcase
      end
    end
  end
end

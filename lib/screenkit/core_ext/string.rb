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

      def camelize(first_letter = :upper)
        split(/_|-/).map.with_index do |part, index|
          if index.zero? && first_letter == :lower
            part.downcase
          else
            part.capitalize
          end
        end.join
      end
    end
  end
end

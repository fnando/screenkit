# frozen_string_literal: true

module ScreenKit
  module CoreExt
    refine NilClass do
      def deep_merge(other)
        {}.deep_merge(other)
      end
    end

    refine Hash do
      def deep_merge(other)
        other = {} if other.nil?

        merger = lambda do |_key, v1, v2|
          if v1.is_a?(Hash) && v2.is_a?(Hash)
            v1.merge(v2, &merger)
          else
            v2
          end
        end

        merge(other, &merger)
      end
    end
  end
end

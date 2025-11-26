# frozen_string_literal: true

require "json"

module ScreenKit
  module CoreExt
    refine JSON.singleton_class do
      def pretty_generate(target, *)
        super(target.as_json, *)
      end

      def dump(target, *, **)
        super(target.as_json, *, **)
      end
    end

    refine Object do
      def to_json(*)
        if respond_to?(:as_json)
          as_json(*).to_json
        else
          super
        end
      end

      def as_json(*)
        if respond_to?(:to_h)
          to_h.transform_values { it.as_json(*) }
        elsif respond_to?(:to_a)
          to_a.map { it.as_json(*) }
        else
          self
        end
      end
    end

    refine Hash do
      def as_json(*)
        transform_values { it.as_json(*) }
      end
    end

    refine Array do
      def as_json(*)
        map { it.as_json(*) }
      end
    end
  end
end

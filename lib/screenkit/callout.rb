# frozen_string_literal: true

module ScreenKit
  class Callout
    # Raised when a style class cannot be found
    UndefinedStyleError = Class.new(StandardError)

    # The callout anchor position. Should be an array with two elements:
    #
    # - Vertical position: "top", "center", or "bottom"
    # - Horizontal position: "left", "center", or "right"
    #
    # @return [Array<String>] e.g., `["top", "center"]`
    attr_reader :anchor

    # The callout margin around the edges. Can be either a number, or an array
    # with 1-4 elements, representing CSS-style margin values.
    #
    # - 1 value: all sides
    # - 2 values: vertical | horizontal
    # - 3 values: top | horizontal | bottom
    # - 4 values: top | right | bottom | left
    #
    # @return [Array<Integer>, Integer] e.g., `20`, `[10, 20, 10, 20]`
    attr_reader :margin

    attr_reader :in_transition, :out_transition, :style,
                :style_props, :style_class

    def self.schema_path
      ScreenKit.root_dir.join("screenkit/schemas/callout.json")
    end

    def self.validate!(attributes)
      errors = JSON::Validator
               .fully_validate("file://#{schema_path}", attributes)

      return if errors.empty?

      raise ArgumentError, "Invalid callout configuration: #{errors.first}"
    end

    def initialize(
      anchor:,
      in_transition:,
      out_transition:,
      margin:,
      style: "default",
      **style_props
    )
      style_name = style || "default"

      self.class.validate!(
        style: style_name,
        anchor:,
        in_transition:,
        out_transition:,
        margin:
      )

      @style_class = resolve_style_class(style_name)
      @anchor = anchor
      @margin = (Array(margin) * 4).take(4)
      @in_transition = Transition.new(**in_transition)
      @out_transition = Transition.new(**out_transition)
      @style = style_class.new(**style_props)
    end

    def render(output_path:, title:, body:)
      style.render(title:, body:, output_path:)
    end

    def resolve_style_class(style)
      error_message = "Style #{style.inspect} is not defined"

      raise UndefinedStyleError, error_message unless style

      Styles.const_get(style.split("_").map(&:capitalize).join)
    rescue NameError
      raise UndefinedStyleError, error_message
    end
  end
end

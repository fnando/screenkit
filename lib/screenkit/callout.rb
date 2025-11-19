# frozen_string_literal: true

module ScreenKit
  class Callout
    using CoreExt

    # Raised when a style class cannot be found
    UndefinedStyleError = Class.new(StandardError)

    extend SchemaValidator

    # The callout anchor position. Should be an array with two elements:
    #
    # - Horizontal position: "left", "center", or "right"
    # - Vertical position: "top", "center", or "bottom"
    #
    # @return [Array<String>] e.g., `["left", "bottom"]`
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

    attr_accessor :in_transition, :out_transition, :style,
                  :style_props, :style_class, :animation, :source, :log_path

    def self.schema_path
      ScreenKit.root_dir.join("screenkit/schemas/refs/callout.json")
    end

    def initialize(
      source:,
      animation:,
      anchor:,
      in_transition:,
      out_transition:,
      margin:,
      style: "default",
      log_path: nil,
      **style_props
    )
      style_name = style || "default"

      self.class.validate!(
        animation:,
        style: style_name,
        anchor:,
        in_transition:,
        out_transition:,
        margin:
      )

      @log_path = log_path
      @source = source
      @animation = animation
      @style_class = resolve_style_class(style_name)
      @anchor = Anchor.new(anchor)
      @margin = Spacing.new(margin)
      @in_transition = Transition.new(**in_transition)
      @out_transition = Transition.new(**out_transition)
      @style = style_class.new(source:, **style_props)
    end

    def render
      if log_path
        File.open(log_path, "w") do |f|
          f << JSON.pretty_generate(
            animation:,
            anchor:,
            margin:,
            in_transition:,
            out_transition:,
            style:
          )
        end
      end

      style.render
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

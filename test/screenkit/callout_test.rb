# frozen_string_literal: true

require "test_helper"

module ScreenKit
  class CalloutTest < Minitest::Test
    test "fails with unresolved style" do
      error = assert_raises(ScreenKit::Callout::UndefinedStyleError) do
        Callout.new(
          margin: 10,
          style: "invalid",
          anchor: %w[top center],
          in_transition: {
            sound: "chime", duration: 0.5,
            animation: "fade_in"
          },
          out_transition: {
            sound: "chime", duration: 0.5,
            animation: "fade_out"
          }
        )
      end

      assert_includes error.message, %[Style "invalid" is not defined]
    end

    test "initializes with configuration" do
      callout = Callout.new(
        margin: 10,
        style: "default",
        anchor: %w[top center],
        in_transition: {sound: "chime", duration: 0.5, animation: "fade_in"},
        out_transition: {sound: "chime", duration: 0.5, animation: "fade_out"},
        icon_path: "icon.png",
        background_color: "#000000",
        shadow_color: "#000000",
        title_style: {color: "#ffffff", size: 32, font_path: "font.ttf"},
        body_style: {color: "#ffffff55", size: 32, font_path: "font.ttf"},
        padding: [0, 0]
      )

      assert_equal [10, 10, 10, 10], callout.margin
      assert_equal %w[top center], callout.anchor
      assert_instance_of ScreenKit::Callout::Styles::Default, callout.style
      assert_instance_of ScreenKit::Transition, callout.in_transition
      assert_instance_of ScreenKit::Transition, callout.out_transition
    end
  end
end

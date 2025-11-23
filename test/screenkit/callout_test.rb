# frozen_string_literal: true

require "test_helper"

module ScreenKit
  class CalloutTest < Minitest::Test
    let(:source) do
      resources_dir = ScreenKit.root_dir
                               .join("screenkit/generators/project/resources")
      ScreenKit::PathLookup.new(resources_dir.join("fonts"))
    end
    let(:font_path) { "open-sans/OpenSans-ExtraBold.ttf" }

    test "fails with unresolved style" do
      error = assert_raises(ScreenKit::Callout::UndefinedStyleError) do
        Callout.new(
          source:,
          animation: "fade",
          margin: 10,
          style: "invalid",
          anchor: %w[center top],
          in_transition: {sound: "chime", duration: 0.5},
          out_transition: {sound: "chime", duration: 0.5}
        )
      end

      assert_includes error.message, %[Style "invalid" is not defined]
    end

    test "initializes with configuration" do
      callout = Callout.new(
        source:,
        animation: "fade",
        margin: 10,
        style: "shadow_block",
        anchor: %w[center top],
        in_transition: {sound: "chime", duration: 0.5},
        out_transition: {sound: "chime", duration: 0.5},
        icon_path: "icon.png",
        background_color: "#000000",
        shadow: "#000000",
        title_style: {color: "#ffffff", size: 32, font_path:},
        body_style: {color: "#ffffff55", size: 32, font_path:},
        padding: [0, 0]
      )

      assert_equal [10, 10, 10, 10], callout.margin.as_json
      assert_equal %w[center top], callout.anchor.as_json
      assert_instance_of ScreenKit::Callout::Styles::ShadowBlock, callout.style
      assert_instance_of ScreenKit::Transition, callout.in_transition
      assert_instance_of ScreenKit::Transition, callout.out_transition
    end
  end
end

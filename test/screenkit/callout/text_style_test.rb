# frozen_string_literal: true

require "test_helper"

module ScreenKit
  class Callout
    class TextStyleTest < Minitest::Test
      let(:source) do
        resources_dir = ScreenKit.root_dir
                                 .join("screenkit/generators/project/resources")
        ScreenKit::PathLookup.new(resources_dir.join("fonts"))
      end

      let(:font_path) { "opensans/OpenSans-ExtraBold.ttf" }

      test "extracts RGB color from hex" do
        style = TextStyle.new(
          source:,
          color: "#ff0000",
          size: 24,
          font_path:
        )

        assert_equal "ff0000", style.rgb_color
      end

      test "returns opacity 1.0 for 6-digit hex" do
        style = TextStyle.new(source:, color: "#ff0000", size: 24, font_path:)

        assert_in_delta(1.0, style.opacity)
      end

      test "extracts opacity from 8-digit hex" do
        style = TextStyle.new(source:, color: "#ff000080", size: 24, font_path:)

        assert_in_delta 0.5, style.opacity, 0.01
      end

      test "handles full opacity in 8-digit hex" do
        style = TextStyle.new(source:, color: "#ff0000ff", size: 24, font_path:)

        assert_in_delta(1.0, style.opacity)
      end
    end
  end
end

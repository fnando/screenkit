# frozen_string_literal: true

require "test_helper"

class InlineBlockTest < Minitest::Test
  let(:source) do
    resources_dir = ScreenKit.root_dir
                             .join("screenkit/generators/project/resources")
    ScreenKit::PathLookup.new(resources_dir.join("fonts"))
  end
  let(:font) { "open-sans/OpenSans-ExtraBold.ttf" }

  test "generates callout image" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::InlineBlock.new(
      source:,
      background_color: "#000000",
      text_style: {color: "#ffffff", font_path: font, size: 40},
      padding: 20,
      width: 600,
      text: "This is the inline callout style and it looks good!".upcase,
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_inline_block.png"), output_path
  end

  test "generates callout image with forced linebreaks" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::InlineBlock.new(
      source:,
      background_color: "#000000",
      text_style: {color: "#ffffff", font_path: font, size: 40},
      padding: 20,
      width: 600,
      text: "Line 1\n\Line 2\nLine 3".upcase,
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_inline_block_linebreaks.png"),
                          output_path
  end
end

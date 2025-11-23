# frozen_string_literal: true

require "test_helper"

class DefaultTest < Minitest::Test
  let(:source) do
    resources_dir = ScreenKit.root_dir
                             .join("screenkit/generators/project/resources")
    ScreenKit::PathLookup.new(
      resources_dir.join("fonts"),
      "/Library/Fonts"
    )
  end
  let(:title_font) { "open-sans/OpenSans-ExtraBold.ttf" }
  let(:body_font) { "open-sans/OpenSans-SemiBold.ttf" }

  test "generates callout image" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::Default.new(
      source:,
      background_color: "#ffff00",
      shadow: "#2242d3",
      title_style: {color: "#000000", size: 40, font_path: title_font},
      body_style: {color: "#ff0000", size: 24, font_path: body_font},
      padding: 50,
      width: 600,
      title: "Default Callout Title",
      body: "This is the body of the default callout style.",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default.png"), output_path
  end

  test "generates callout image using system font" do
    skip unless RUBY_PLATFORM.include?("darwin")

    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::Default.new(
      source:,
      background_color: "#ffff00",
      shadow: "#2242d3",
      title_style: {
        color: "#000000",
        size: 40,
        font_path: "SF-Pro-Text-Heavy.otf"
      },
      body_style: {
        color: "#ff0000",
        size: 24,
        font_path: "SF-Pro-Text-Semibold.otf"
      },
      padding: 50,
      width: 600,
      title: "Default Callout Title",
      body: "This is the body of the default callout style.",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_system_font.png"),
                          output_path
  end

  test "generates callout image with just the title" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::Default.new(
      source:,
      background_color: "#ffff00",
      shadow: "#2242d3",
      title_style: {color: "#000000", size: 40, font_path: title_font},
      body_style: {color: "#ff0000", size: 24, font_path: body_font},
      padding: 50,
      width: 600,
      title: "Default Callout Title",
      body: "",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_title.png"), output_path
  end

  test "generates callout image with just the body" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::Default.new(
      source:,
      background_color: "#ffff00",
      shadow: "#2242d3",
      title_style: {color: "#000000", size: 40, font_path: title_font},
      body_style: {color: "#ff0000", size: 24, font_path: body_font},
      padding: 50,
      width: 600,
      title: "",
      body: "This is the body of the default callout style.",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_body.png"), output_path
  end

  test "generates callout image with lengthy callout" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::Default.new(
      source:,
      background_color: "#ffff00",
      shadow: "#2242d3",
      title_style: {color: "#000000", size: 40, font_path: title_font},
      body_style: {color: "#ff0000", size: 24, font_path: body_font},
      padding: 50,
      width: 600,
      title: "Lorem ipsum dolor sit amet consectetur adipiscing elit quisque " \
             "faucibus.",
      body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do " \
            "eiusmod tempor incididunt ut labore et dolore magna aliqua. " \
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco " \
            "laboris nisi ut aliquip ex ea commodo consequat.",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_lengthy_callout.png"),
                          output_path
  end

  test "generates callout image with no shadow" do
    output_path = create_tmp_path(:png)
    style = ScreenKit::Callout::Styles::Default.new(
      source:,
      background_color: "#ffff00",
      shadow: false,
      title_style: {color: "#000000", size: 40, font_path: title_font},
      body_style: {color: "#ff0000", size: 24, font_path: body_font},
      padding: 50,
      width: 600,
      title: "Default Callout Title",
      body: "This is the body of the default callout style.",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_no_shadow.png"),
                          output_path
  end
end

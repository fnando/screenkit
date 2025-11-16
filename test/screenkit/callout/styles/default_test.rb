# frozen_string_literal: true

require "test_helper"

class DefaultTest < Minitest::Test
  test "generates callout image" do
    style = ScreenKit::Callout::Styles::Default.new(
      background_color: "#ffff00",
      shadow_color: "#2242d3",
      title_style: {
        color: "#000000",
        size: 40,
        font_path: opensans_extra_bold_path
      },
      body_style: {
        color: "#ff0000",
        size: 24,
        font_path: opensans_semibold_path
      },
      padding: 50,
      width: 600
    )

    output_path = create_tmp_path(:png)

    style.render(
      title: "Default Callout Title",
      body: "This is the body of the default callout style.",
      output_path:
    )

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default.png"), output_path
  end

  test "generates callout image with just the title" do
    style = ScreenKit::Callout::Styles::Default.new(
      background_color: "#ffff00",
      shadow_color: "#2242d3",
      title_style: {
        color: "#000000",
        size: 40,
        font_path: opensans_extra_bold_path
      },
      body_style: {
        color: "#ff0000",
        size: 24,
        font_path: opensans_semibold_path
      },
      padding: 50,
      width: 600
    )

    output_path = create_tmp_path(:png)

    style.render(
      title: "Default Callout Title",
      body: "",
      output_path:
    )

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_title.png"), output_path
  end

  test "generates callout image with just the body" do
    style = ScreenKit::Callout::Styles::Default.new(
      background_color: "#ffff00",
      shadow_color: "#2242d3",
      title_style: {
        color: "#000000",
        size: 40,
        font_path: opensans_extra_bold_path
      },
      body_style: {
        color: "#ff0000",
        size: 24,
        font_path: opensans_semibold_path
      },
      padding: 50,
      width: 600
    )

    output_path = create_tmp_path(:png)

    style.render(
      title: "",
      body: "This is the body of the default callout style.",
      output_path:
    )

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_body.png"), output_path
  end

  test "generates callout image with lengthy callout" do
    style = ScreenKit::Callout::Styles::Default.new(
      background_color: "#ffff00",
      shadow_color: "#2242d3",
      title_style: {
        color: "#000000",
        size: 40,
        font_path: opensans_extra_bold_path
      },
      body_style: {
        color: "#ff0000",
        size: 24,
        font_path: opensans_semibold_path
      },
      padding: 50,
      width: 600
    )

    output_path = create_tmp_path(:png)

    style.render(
      title: "Lorem ipsum dolor sit amet consectetur adipiscing elit quisque " \
             "faucibus.",
      body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do " \
            "eiusmod tempor incididunt ut labore et dolore magna aliqua. " \
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco " \
            "laboris nisi ut aliquip ex ea commodo consequat.",
      output_path:
    )

    assert_path_exists output_path
    assert_similar_images fixtures("callout_default_lengthy_callout.png"),
                          output_path
  end
end

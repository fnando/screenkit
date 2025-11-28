# frozen_string_literal: true

require "test_helper"

class SocialTest < Minitest::Test
  setup { slow_test }

  let(:source) do
    resources_dir = ScreenKit.root_dir
                             .join("generators/project/resources")
    ScreenKit::PathLookup.new(
      fixtures_dir,
      ScreenKit.root_dir.join("resources"),
      resources_dir.join("fonts"),
      "/Library/Fonts"
    )
  end
  let(:title_font) { "open-sans/OpenSans-ExtraBold.ttf" }
  let(:body_font) { "open-sans/OpenSans-SemiBold.ttf" }

  test "generates spotify image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "spotify",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_spotify.png"), output_path
  end

  test "generates linkedin image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "linkedin",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_linkedin.png"), output_path
  end

  test "generates dribbble image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "dribbble",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_dribbble.png"), output_path
  end

  test "generates tiktok image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "tiktok",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_tiktok.png"), output_path
  end

  test "generates youtube image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "youtube",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_youtube.png"), output_path
  end

  test "generates snap image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "snap",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_snap.png"), output_path
  end

  test "generates mastodon image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "mastodon",
      text: "example.com/@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_mastodon.png"), output_path
  end

  test "generates blog image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "blog",
      text: "example.com",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_blog.png"), output_path
  end

  test "generates twitch image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "twitch",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_twitch.png"), output_path
  end

  test "generates github image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "github",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_github.png"), output_path
  end

  test "generates soundcloud image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "soundcloud",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_soundcloud.png"), output_path
  end

  test "generates discord image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "discord",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_discord.png"), output_path
  end

  test "generates bsky image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "bsky",
      text: "@some_account.bsky.social",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_bsky.png"), output_path
  end

  test "generates instagram image" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      preset: "instagram",
      text: "@some_account",
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_instagram.png"), output_path
  end

  test "generates custom callout" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::Social.new(
      source:,
      text: "@some_account",
      label: "CUSTOM",
      icon: {
        path: "custom.png",
        background_color: "#F29958"
      },
      background_color: "#A6693D",
      label_style: {
        color: "#ffffff88",
        size: 24,
        font_path: "open-sans/OpenSans-ExtraBold.ttf"
      },
      text_style: {
        color: "#ffffff",
        size: 50,
        font_path: "open-sans/OpenSans-ExtraBold.ttf"
      },
      output_path:
    )

    style.render

    assert_path_exists output_path
    assert_similar_images fixtures("callout_social_custom.png"), output_path
  end
end

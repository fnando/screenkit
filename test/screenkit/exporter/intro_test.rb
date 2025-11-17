# frozen_string_literal: true

require "test_helper"

class IntroTest < Minitest::Test
  let(:text) { "CREATING YOUR FIRST SCREENCAST WITH SCREENKIT" }
  let(:source) do
    resources_dir = ScreenKit.root_dir
                             .join("screenkit/generators/project/resources")
    ScreenKit::PathLookup.new(
      resources_dir,
      resources_dir.join("images"),
      resources_dir.join("sounds"),
      resources_dir.join("fonts")
    )
  end

  test "exports intro segment with background color" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:background] = "#100f50"

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_with_bgcolor.mp4"), intro_path)
  end

  test "exports intro segment with sound" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:background] = "#100f50"
    config[:sound] = "chime.mp3"

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_with_sound.mp4"), intro_path)
    assert_has_audio(intro_path)
    assert_lufs(intro_path, expected: -21.3)
  end

  test "exports intro segment with background image" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:background] =
      fixtures("sean-sinclair-C_NJKfnTR5A-unsplash.jpg").to_s

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_with_bg_image.mp4"), intro_path)
  end

  test "exports intro segment logo vertically centered" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:logo][:y] = "center"

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_logo_vertical.mp4"), intro_path)
  end

  test "exports intro segment logo horizontally centered" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:logo][:x] = "center"

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_logo_horizontal.mp4"), intro_path)
  end

  test "exports intro segment text horizontally centered" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:title][:x] = "center"
    config[:logo][:x] = "center"

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_text_horizontal.mp4"), intro_path)
  end

  test "exports intro segment with no sound" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:sound] = false

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_no_sound.mp4"), intro_path)
    assert_lufs(intro_path, expected: -70)
  end

  test "exports intro segment with custom volume" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:intro)
    config[:sound] = {path: "chime.mp3", volume: 0.2}

    intro_exporter = ScreenKit::Exporter::Intro.new(config:, text:, source:)
    intro_path = create_tmp_path(:mp4)
    intro_exporter.export(intro_path)

    assert_similar_videos(fixtures("intro_volume_20_percent.mp4"), intro_path)
    assert_has_audio(intro_path)
    assert_lufs(intro_path, expected: -34.6)
  end
end

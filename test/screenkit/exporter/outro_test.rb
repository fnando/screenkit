# frozen_string_literal: true

require "test_helper"

class OutroTest < Minitest::Test
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

  test "exports outro segment background color" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:background] = "#100f50"

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_with_bgcolor.mp4"), outro_path)
  end

  test "exports outro segment with sound" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:background] = "#100f50"

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_with_sound.mp4"), outro_path)
    assert_has_audio(outro_path)
    assert_lufs(outro_path, expected: -21.3)
  end

  test "exports outro segment with background image" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:background] =
      fixtures("sean-sinclair-C_NJKfnTR5A-unsplash.jpg").to_s

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_with_bg_image.mp4"), outro_path)
  end

  test "exports outro segment with background video" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:background] = fixtures("bg_24fps.mp4").to_s

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_with_bg_video.mp4"), outro_path)
  end

  test "exports outro segment vertically centered" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:logo][:x] = 50

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_with_vertical.mp4"), outro_path)
  end

  test "exports outro segment horizontally centered" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:logo][:y] = 800

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_with_horizontal.mp4"), outro_path)
  end

  test "exports outro with no sound" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:sound] = false

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_no_sound.mp4"), outro_path)
    assert_lufs(outro_path, expected: -70)
  end

  test "exports outro segment with custom volume" do
    config_path = fixtures("screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config = config.scenes.fetch(:outro)
    config[:sound] = {path: config[:sound], volume: 0.2}

    outro_exporter = ScreenKit::Exporter::Outro.new(config:, source:)
    outro_path = create_tmp_path(:mp4)
    outro_exporter.export(outro_path)

    assert_similar_videos(fixtures("outro_volume_20_percent.mp4"), outro_path)
    assert_has_audio(outro_path)
    assert_lufs(outro_path, expected: -34.6)
  end
end

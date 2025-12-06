# frozen_string_literal: true

require "test_helper"

class PlaywrightTest < Minitest::Test
  setup do
    next unless `which playwright-video`.strip.empty?
    skip "playwright-video is not installed"
  end

  test "exports a playwright script correctly" do
    script_path = fixtures("blog.playwright.mjs")
    output_path = create_tmp_path(:mp4)

    playwright_exporter = ScreenKit::Exporter::Playwright.new(script_path:)

    playwright_exporter.export(output_path)

    assert_path_exists output_path
    assert_similar_videos(
      fixtures("playwright.mp4"),
      output_path,
      threshold: 0.02
    )
  end

  test "exports a playwright script correctly with custom config" do
    script_path = fixtures("blog.playwright.mjs")
    output_path = create_tmp_path(:mp4)

    playwright_exporter =
      ScreenKit::Exporter::Playwright.new(
        script_path:,
        options: {color_scheme: "light"}
      )

    playwright_exporter.export(output_path)

    assert_path_exists output_path
    assert_similar_videos(
      fixtures("playwright_custom_config.mp4"),
      output_path,
      threshold: 0.02
    )
  end
end

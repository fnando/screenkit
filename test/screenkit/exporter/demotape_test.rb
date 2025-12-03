# frozen_string_literal: true

require "test_helper"

class DemotapeTest < Minitest::Test
  test "exports a demotape correctly" do
    demotape_path = fixtures("hello.tape")
    output_path = create_tmp_path(:mp4)

    demotape_exporter =
      ScreenKit::Exporter::Demotape.new(demotape_path:)

    demotape_exporter.export(output_path)

    assert_path_exists output_path
    assert_similar_videos(
      fixtures("demotape.mp4"),
      output_path,
      threshold: 0.02
    )
  end

  test "exports a demotape correctly with custom config" do
    demotape_path = fixtures("hello.tape")
    output_path = create_tmp_path(:mp4)

    demotape_exporter =
      ScreenKit::Exporter::Demotape.new(
        demotape_path:,
        options: {theme: "default_light"}
      )

    demotape_exporter.export(output_path)

    assert_path_exists output_path
    assert_similar_videos(
      fixtures("demotape_custom_config.mp4"),
      output_path,
      threshold: 0.025
    )
  end
end

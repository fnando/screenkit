# frozen_string_literal: true

require "test_helper"

class VideoTest < Minitest::Test
  include ScreenKit::Utils

  test "copies video with correct fps over" do
    input_path = fixtures("24fps.mp4")
    output_path = create_tmp_path(:mp4)

    video_exporter = ScreenKit::Exporter::Video.new(input_path: input_path)
    video_exporter.export(output_path)

    assert File.file?(output_path)
    assert_equal 24, fps(output_path)
    assert_similar_videos(input_path, output_path)
  end

  test "converts video with incorrect fps" do
    input_path = fixtures("60fps.mp4")
    output_path = create_tmp_path(:mp4)

    video_exporter = ScreenKit::Exporter::Video.new(input_path: input_path)
    video_exporter.export(output_path)

    assert File.file?(output_path)
    assert_equal 24, fps(output_path)
    assert_similar_videos(input_path, output_path)
  end
end

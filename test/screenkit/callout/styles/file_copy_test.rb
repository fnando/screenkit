# frozen_string_literal: true

require "test_helper"

class FileCopyTest < Minitest::Test
  setup { slow_test }

  let(:resources_dir) do
    ScreenKit.root_dir.join("generators/project/resources")
  end

  let(:source) do
    ScreenKit::PathLookup.new(resources_dir)
  end

  test "copies files correctly" do
    output_path = create_tmp_path(:png)

    style = ScreenKit::Callout::Styles::FileCopy.new(
      source:,
      output_path:,
      file_path: "images/logo.png"
    )

    style.render

    assert_similar_images resources_dir.join("images/logo.png"),
                          output_path
  end
end

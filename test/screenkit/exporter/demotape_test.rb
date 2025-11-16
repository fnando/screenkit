# frozen_string_literal: true

require "test_helper"

class DemotapeTest < Minitest::Test
  test "exports a demotape correctly" do
    demotape_path = fixtures("hello.tape")
    output_path = create_tmp_path(:mp4)

    demotape_exporter =
      ScreenKit::Exporter::Demotape.new(demotape_path: demotape_path)

    demotape_exporter.export(output_path)

    assert_path_exists output_path
  end
end

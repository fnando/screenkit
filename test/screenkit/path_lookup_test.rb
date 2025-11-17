# frozen_string_literal: true

require "test_helper"

class PathLookupTest < Minitest::Test
  test "looks up paths correctly" do
    lookup = ScreenKit::PathLookup.new(
      Dir.pwd,
      __dir__,
      ScreenKit.root_dir
    )

    assert_equal Pathname(__FILE__),
                 lookup.search("path_lookup_test.rb")
    assert_equal Pathname(__FILE__),
                 lookup.search("test/screenkit/path_lookup_test.rb")
    assert_equal ScreenKit.root_dir.join("screenkit"),
                 lookup.search("screenkit")
  end

  test "looks up dir/" do
    lookup = ScreenKit::PathLookup.new(
      Dir.pwd,
      __dir__,
      ScreenKit.root_dir
    )

    assert_equal Pathname.pwd.join("test/"), lookup.search("test/")
  end

  test "fails with missing file" do
    lookup = ScreenKit::PathLookup.new

    error = assert_raises ScreenKit::FileEntryNotFoundError do
      lookup.search("missing.txt")
    end

    assert_equal %[No file entry found for "missing.txt"], error.message
  end
end

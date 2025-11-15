# frozen_string_literal: true

require "test_helper"

class StringTest < Minitest::Test
  using ScreenKit::CoreExt

  test "dasherizes a string" do
    original = "This is a Test_string! It's Ünicode & Special--Characters."
    expected = "this-is-a-test-string-its-unicode-special-characters"

    assert_equal expected, original.dasherize
  end
end

# frozen_string_literal: true

require "test_helper"

class StringTest < Minitest::Test
  using ScreenKit::CoreExt

  test "dasherizes a string" do
    original = "This is a Test_string! It's Ünicode & Special--Characters."
    expected = "this-is-a-test-string-its-unicode-special-characters"

    assert_equal expected, original.dasherize
    assert_equal "this-is-a-test-string", "this_is_a_test_string".dasherize
    assert_equal "camel-case", "CamelCase".dasherize
    assert_equal "http-response", "HTTPResponse".dasherize
  end

  test "camelizes a string" do
    original = "this-is-a-test_string"
    expected_upper = "ThisIsATestString"
    expected_lower = "thisIsATestString"

    assert_equal expected_upper, original.camelize(:upper)
    assert_equal expected_lower, original.camelize(:lower)
  end

  test "underscores a string" do
    assert_equal "this_is_a_test_string", "this-is-a-test-string".underscore
    assert_equal "camel_case", "CamelCase".underscore
    assert_equal "http_response", "HTTPResponse".underscore
  end
end

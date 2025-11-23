# frozen_string_literal: true

require "test_helper"

class TimeFormatterTest < Minitest::Test
  test "formats seconds" do
    assert_equal 0, ScreenKit::TimeFormatter.parse("00:00:00")
    assert_equal 15, ScreenKit::TimeFormatter.parse("00:00:15")
    assert_equal 30, ScreenKit::TimeFormatter.parse("00:00:30")
    assert_equal 59, ScreenKit::TimeFormatter.parse("00:00:59")
  end

  test "formats minutes" do
    assert_equal 180, ScreenKit::TimeFormatter.parse("00:03:00")
    assert_equal 195, ScreenKit::TimeFormatter.parse("00:03:15")
    assert_equal 765, ScreenKit::TimeFormatter.parse("00:12:45")
    assert_equal 3599, ScreenKit::TimeFormatter.parse("00:59:59")
  end

  test "formats hours" do
    assert_equal 3600, ScreenKit::TimeFormatter.parse("01:00:00")
    assert_equal 3600, ScreenKit::TimeFormatter.parse("1:00:00")
    assert_equal 8130, ScreenKit::TimeFormatter.parse("2:15:30")
  end

  test "formats only with provided segments" do
    assert_equal 5, ScreenKit::TimeFormatter.parse("05")
    assert_equal 15, ScreenKit::TimeFormatter.parse("00:15")
    assert_equal 75, ScreenKit::TimeFormatter.parse("01:15")
    assert_equal 75, ScreenKit::TimeFormatter.parse("1:15")
  end

  test "returns numeric values as it is" do
    assert_equal 63, ScreenKit::TimeFormatter.parse(63)
  end
end

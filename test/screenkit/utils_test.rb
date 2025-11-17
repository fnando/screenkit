# frozen_string_literal: true

require "test_helper"

class UtilsTest < Minitest::Test
  include ScreenKit::Utils

  test "returns relative path from pwd" do
    assert_equal "test/screenkit", relative_path(__dir__).to_s
  end

  test "returns absolute when path two dirs away from base" do
    assert_equal "/tmp",
                 relative_path("/tmp", from: "/home/user").to_s
  end
end

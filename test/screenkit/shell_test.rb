# frozen_string_literal: true

require "test_helper"

class ShellTest < Minitest::Test
  include ScreenKit::Shell

  test "executes commands successfully" do
    run_command("echo", "Hello, World!") => [out, err]

    assert_equal "Hello, World!\n", out
    assert_empty err
  end

  test "raises error on command failure" do
    error = nil

    stdout, stderr = capture_io do
      error = assert_raises(ScreenKit::Shell::Error) do
        run_command("false")
      end
    end

    assert_empty stdout
    assert_includes stderr, "Command failed: false\n"
    assert_match(/"false" failed with exit=1/, error.message)
  end
end

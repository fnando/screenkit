# frozen_string_literal: true

require "test_helper"

class SayTest < Minitest::Test
  test "generates voice using say" do
    skip "macOS only" unless RUBY_PLATFORM.include?("darwin")

    output_path = create_tmp_path(:aiff)

    engine = ScreenKit::TTS::Say.new(engine: "say")
    engine.generate(text: "Test", output_path:)

    assert output_path.exist?
  end

  test "generates using custom voice" do
    skip "macOS only" unless RUBY_PLATFORM.include?("darwin")

    output_path = create_tmp_path(:aiff)

    engine = ScreenKit::TTS::Say.new(engine: "say", voice: "Alex")
    engine.generate(text: "Test", output_path:)

    assert output_path.exist?
  end

  test "generates using custom rate" do
    skip "macOS only" unless RUBY_PLATFORM.include?("darwin")

    output_path = create_tmp_path(:aiff)

    engine = ScreenKit::TTS::Say.new(engine: "say", rate: 300)
    engine.generate(text: "Test", output_path:)

    assert output_path.exist?
  end
end

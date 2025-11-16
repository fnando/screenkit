# frozen_string_literal: true

require "test_helper"

class SayTest < Minitest::Test
  test "generates voice using say" do
    skip "macOS only" unless RUBY_PLATFORM.include?("darwin")

    output_path = fixtures("say.m4a")

    ScreenKit::VoiceEngines::Say.generate_voiceover(
      text: "Test",
      output_path: output_path.to_s,
      rate: 200
    )

    assert output_path.exist?
  end
end

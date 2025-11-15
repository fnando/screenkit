# frozen_string_literal: true

require "test_helper"

class SayTest < Minitest::Test
  test "generates voice using say" do
    output_path = tmp_dir.join("say.m4a")

    ScreenKit::VoiceEngines::Say.generate_voiceover(
      text: "Test",
      output_path: output_path.to_s,
      rate: 200,
      quality: 100
    )

    assert output_path.exist?
  end
end

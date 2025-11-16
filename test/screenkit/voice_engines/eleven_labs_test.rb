# frozen_string_literal: true

require "test_helper"

class ElevenLabsTest < Minitest::Test
  test "generates voice using elevenlabs" do
    api_key = ENV.fetch("ELEVENLABS_API_KEY", nil)
    output_path = fixtures("elevenlabs.mp3")
    skip if output_path.file?

    ScreenKit::VoiceEngines::ElevenLabs.generate_voiceover(
      output_path:,
      api_key:,
      text: "Test",
      voice_id: "yhFUAoS32gPDJFQHbH68"
    )
  end
end

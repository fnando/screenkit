# frozen_string_literal: true

require "test_helper"

class ElevenLabsTest < Minitest::Test
  test "generates voice using elevenlabs" do
    api_key = ENV.fetch("ELEVENLABS_API_KEY", nil)
    skip "No API key defined" unless api_key

    WebMock.allow_net_connect!

    output_path = fixtures("elevenlabs.mp3")
    skip if output_path.file?

    engine = ScreenKit::TTS::ElevenLabs.new(
      api_key:,
      voice_id: "yhFUAoS32gPDJFQHbH68"
    )

    engine.generate(output_path:, text: "Test")

    assert output_path.exist?
  end
end

# frozen_string_literal: true

require "test_helper"

class ElevenLabsTest < Minitest::Test
  test "normalizes api key" do
    engine = ScreenKit::TTS::ElevenLabs.new(
      api_key: "eleven_labs:my_api_key"
    )

    assert_equal "my_api_key", engine.api_key
  end

  test "generates voice using elevenlabs" do
    api_key = ENV.fetch("ELEVENLABS_API_KEY", nil)
    skip "No API key defined" unless api_key

    api_key = "eleven_labs:#{api_key}"
    output_path = fixtures("elevenlabs.mp3")
    log_path = create_tmp_path(:txt)

    skip "Fixture file already exists" if output_path.file?
    WebMock.allow_net_connect! if defined?(WebMock)

    engine = ScreenKit::TTS::ElevenLabs.new(
      api_key:,
      voice_id: "yhFUAoS32gPDJFQHbH68"
    )

    engine.generate(output_path:, text: "Test", log_path:)

    assert output_path.exist?
    refute_includes log_path.read, api_key
  end
end

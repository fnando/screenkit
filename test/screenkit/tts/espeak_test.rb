# frozen_string_literal: true

require "test_helper"

class EspeakTest < Minitest::Test
  test "generates voice using espeak" do
    output_path = create_tmp_path(:wav)

    engine = ScreenKit::TTS::Espeak.new(engine: "espeak")
    engine.generate(text: "Test", output_path:)

    assert output_path.exist?
  end

  test "generates using custom voice" do
    output_path = create_tmp_path(:wav)

    engine = ScreenKit::TTS::Espeak.new(engine: "espeak", voice: "pt-br")
    engine.generate(text: "Testando", output_path:)

    assert output_path.exist?
  end

  test "generates using custom rate" do
    output_path = create_tmp_path(:wav)

    engine = ScreenKit::TTS::Espeak.new(engine: "espeak", rate: 300)
    engine.generate(text: "Test", output_path:)

    assert output_path.exist?
  end
end

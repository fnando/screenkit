# frozen_string_literal: true

require "test_helper"

class SchemaTTSTest < Minitest::Test
  let(:validator) do
    Module.new do
      extend ScreenKit::SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("schemas/refs/tts.json")
      end
    end
  end

  test "accepts `tts: false`" do
    assert validator.validate!(false)
  end

  test "fails with `tts: true`" do
    error = assert_raises(ArgumentError) { validator.validate!(true) }
    assert_includes error.message,
                    "Invalid attributes: The property '#/' of type boolean " \
                    "did not match any of the required schemas"
  end

  test "accepts `say` options" do
    assert validator.validate!(id: "say", engine: "say")
  end

  test "accepts `espeak` options" do
    assert validator.validate!(id: "espeak", engine: "espeak")
  end

  test "accepts `eleven_labs` options" do
    assert validator.validate!(
      id: "eleven_labs",
      engine: "eleven_labs",
      voice_id: "abc"
    )
  end

  test "accepts custom engines" do
    assert validator.validate!(
      engine: "custom",
      id: "custom",
      some_property: "abc"
    )
  end
end

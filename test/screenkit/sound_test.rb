# frozen_string_literal: true

require "test_helper"

class SoundTest < Minitest::Test
  let(:resources_dir) do
    ScreenKit.root_dir.join("generators/project/resources")
  end

  let(:source) do
    ScreenKit::PathLookup.new(
      ScreenKit.root_dir.join("resources"),
      resources_dir,
      resources_dir.join("images"),
      resources_dir.join("sounds"),
      resources_dir.join("fonts")
    )
  end

  test "sets up sound from boolean" do
    sound = ScreenKit::Sound.new(input: false, source:)
    dir = ScreenKit.root_dir.join("resources")

    assert_equal dir.join("mute.mp3"), sound.path
    assert_in_delta(1.0, sound.volume)
  end

  test "sets up sound from partial hash" do
    sound = ScreenKit::Sound.new(input: {path: "chime.mp3"}, source:)

    assert_equal resources_dir.join("sounds/chime.mp3"), sound.path
    assert_in_delta(1.0, sound.volume)
  end

  test "sets up sound from string" do
    sound = ScreenKit::Sound.new(input: "chime.mp3", source:)

    assert_equal resources_dir.join("sounds/chime.mp3"), sound.path
    assert_in_delta(1.0, sound.volume)
  end
end

# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  test "validates project config" do
    config_path = Pathname
                  .pwd
                  .join("lib/screenkit/generators/project/screenkit.yml")
    config = ScreenKit::Project::Config.load_file(config_path)

    assert_instance_of ScreenKit::Project::Config, config
  end

  test "fails when loading invalid config" do
    error = assert_raises(ArgumentError) do
      ScreenKit::Project::Config.load({})
    end

    assert_match(/did not contain a required property/, error.message)
  end

  test "fails when loading missing file" do
    error = assert_raises(ScreenKit::FileNotFoundError) do
      ScreenKit::Project::Config.load_file("/invalid.yml")
    end

    assert_match(%r{Config file not found: /invalid}, error.message)
  end

  test "processes path values as Pathname" do
    config_path = Pathname
                  .pwd
                  .join("lib/screenkit/generators/project/screenkit.yml")
    config = ScreenKit::Project::Config.load_file(config_path)

    assert_instance_of Pathname, config.episode_dir
    assert_instance_of Pathname, config.sounds_dir
    assert_instance_of Pathname, config.backtracks_dir
  end
end

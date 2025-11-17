# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  test "validates project config" do
    config_path = Pathname
                  .pwd
                  .join("lib/screenkit/generators/project/screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)

    assert_instance_of ScreenKit::Config::Project, config
  end

  test "fails when loading invalid config" do
    error = assert_raises(ArgumentError) do
      ScreenKit::Config::Project.load({})
    end

    assert_match(/did not contain a required property/, error.message)
  end

  test "fails when loading missing file" do
    error = assert_raises(ScreenKit::FileNotFoundError) do
      ScreenKit::Config::Project.load_file("/invalid.yml")
    end

    assert_match(%r{Config file not found: /invalid}, error.message)
  end

  test "processes path values as Pathname" do
    config_path = Pathname
                  .pwd
                  .join("lib/screenkit/generators/project/screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)

    assert_instance_of Pathname, config.episode_dir
  end
end

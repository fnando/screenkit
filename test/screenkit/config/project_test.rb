# frozen_string_literal: true

require "test_helper"

class ProjectTest < Minitest::Test
  test "validates project config" do
    config_path = ScreenKit.root_dir.join("generators/project/screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)

    assert_instance_of ScreenKit::Config::Project, config
  end

  test "renders erb in config file" do
    config_path = ScreenKit.root_dir.join("generators/project/screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)
    config.resources_dir.clear
    config.resources_dir.push %[<%= ScreenKit.resources_dir %>]
    config_path = create_tmp_path(:yml)
    config_path.write(YAML.dump(config.to_h))

    config = ScreenKit::Config::Project.load_file(config_path)
    expected_path = ScreenKit.root_dir.join("resources")

    assert_equal [expected_path.to_s], config.resources_dir
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
    config_path = ScreenKit.root_dir.join("generators/project/screenkit.yml")
    config = ScreenKit::Config::Project.load_file(config_path)

    assert_instance_of Pathname, config.episode_dir
  end
end

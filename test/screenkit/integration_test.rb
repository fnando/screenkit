# frozen_string_literal: true

require "test_helper"

class IntegrationTest < Minitest::Test
  let(:screencasts_path) { "tmp/screencasts" }

  setup { FileUtils.rm_rf(screencasts_path) }

  def screenkit(*, **)
    exe_dir = File.join(Dir.pwd, "exe")
    env = ENV.to_h.merge("PATH" => "#{exe_dir}:#{ENV.fetch('PATH', nil)}")

    system(
      env,
      "bundle",
      "exec",
      "screenkit",
      *,
      exception: true,
      out: "tmp/out.txt",
      err: "tmp/err.txt",
      **
    )
  end

  test "generates project" do
    slow_test

    screenkit "new", screencasts_path

    assert File.directory?(screencasts_path)
    assert_equal fixtures("new_project_out.txt").read, File.read("tmp/out.txt")
  end

  test "generates episode" do
    slow_test

    screenkit "new", "tmp/screencasts"
    screenkit "episode",
              "new",
              "--title",
              "My First Episode",
              chdir: screencasts_path

    assert File.directory?("tmp/screencasts/episodes/001-my-first-episode")
    assert_includes File.read("tmp/out.txt"),
                    fixtures("new_episode_out.txt").read
  end

  test "exports generated episode" do
    slow_test

    screenkit "new", "tmp/screencasts"
    screenkit "episode",
              "new",
              "--title",
              "My First Episode",
              chdir: screencasts_path
    screenkit "episode",
              "export",
              "--dir",
              "episodes/001-my-first-episode",
              chdir: screencasts_path

    assert File.file?(
      "#{screencasts_path}/output/001-my-first-episode/001-my-first-episode.mp4"
    )
    assert_includes File.read("tmp/out.txt"), "Exported episode in"
  end
end

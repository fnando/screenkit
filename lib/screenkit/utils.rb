# frozen_string_literal: true

module ScreenKit
  module Utils
    def fps(path)
      cmd = "ffprobe -v error -select_streams v:0 -show_entries " \
            "stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1"
      `#{cmd} #{path}`.strip.to_f
    end

    def duration(path)
      return 0.0 unless path.file?

      cmd = "ffprobe -v error -show_entries format=duration -of " \
            "default=noprint_wrappers=1:nokey=1"
      `#{cmd} #{path}`.strip.to_f
    end

    def elapsed
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      finished = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      [finished - started, result]
    end

    def relative_path(path, from: Pathname.pwd)
      path = Pathname(path)
      candidate = path.relative_path_from(from)
      parent = ["..", File::SEPARATOR, ".."].join

      return path.expand_path if candidate.to_s.start_with?(parent)

      candidate
    end
  end
end

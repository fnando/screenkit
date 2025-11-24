# frozen_string_literal: true

module ScreenKit
  module Utils
    def has_audio?(path) #  rubocop:disable Naming/PredicatePrefix
      cmd = "ffprobe -v error -select_streams a:0 -show_entries " \
            "stream=codec_type -of default=noprint_wrappers=1:nokey=1"
      `#{cmd} #{path}`.strip == "audio"
    end

    def fps(path)
      cmd = "ffprobe -v error -select_streams v:0 -show_entries " \
            "stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1"
      rate = `#{cmd} #{path}`.strip

      if rate.include?("/")
        numerator, denominator = rate.split("/").map(&:to_f)
        numerator / denominator
      else
        rate.to_f
      end
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

    def image_size(path, hi_res: true)
      factor = hi_res ? 2 : 1
      image = MiniMagick::Image.open(path.to_s)
      [image.width / factor, image.height / factor]
    end

    def video_file?(path)
      ContentType.video.include?(File.extname(path).downcase.delete_prefix("."))
    end

    def calculate_position(
      anchor:,
      margin:,
      width:,
      height:,
      base_width: 1920,
      base_height: 1080
    )
      x = case anchor.horizontal
          when "left"
            margin.left
          when "center"
            ((base_width - width) / 2.0).round
          when "right"
            (base_width - width - margin.right)
          else
            0
          end

      y = case anchor.vertical
          when "top"
            margin.top
          when "center"
            ((base_height - height) / 2.0).round
          when "bottom"
            (base_height - height - margin.bottom)
          else
            0
          end

      [x, y]
    end
  end
end

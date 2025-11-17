# frozen_string_literal: true

require "English"
require "simplecov"
SimpleCov.start

require "bundler/setup"
require "screen_kit"

require "minitest/utils"
require "minitest/autorun"

require "securerandom"

Dir["#{__dir__}/support/**/*.rb"].each do |file|
  require file
end

FileUtils.rm_rf(File.join(Dir.pwd, "tmp"))

module Minitest
  class Test
    setup do
      FileUtils.mkdir_p(tmp_dir)
    end

    def tmp_dir
      Pathname.pwd.join("tmp")
    end

    def fixtures(path)
      Pathname(__dir__).join("fixtures", path)
    end

    def create_tmp_path(ext)
      ext = ext.to_s.gsub(/^\./, "")
      tmp_dir.join([SecureRandom.hex(10), ext].join("."))
    end

    def assert_similar_images(expected_path, actual_path, threshold: 0.01)
      $original_stderr = $stderr # rubocop:disable Style/GlobalVars
      $stderr = StringIO.new
      expected_path = Pathname(expected_path)
                      .relative_path_from(Pathname.pwd)
      actual_path = Pathname(actual_path)
                    .relative_path_from(Pathname.pwd)

      unless File.file?(expected_path)
        FileUtils.mkdir_p(File.dirname(expected_path))
        FileUtils.copy(actual_path, expected_path)
        return
      end

      # Use ImageMagick's compare with RMSE (Root Mean Square Error) metric
      # Returns a normalized value between 0 (identical) and 1
      # (completely different)
      compare = MiniMagick.compare
      compare << "-metric"
      compare << "RMSE"
      compare << actual_path
      compare << expected_path
      compare << "-format"
      compare << "%[distortion]"
      compare << "null:"
      result = compare.call

      # Parse the distortion value (format is like "0.0123456 (RMSE)")
      distortion = result[/^[\d.]+/].to_f

      assert_operator distortion,
                      :<,
                      threshold,
                      "Images differ too much. Distortion: #{distortion}, " \
                      "Threshold: #{threshold}\n" \
                      "Actual: #{actual_path}\n" \
                      "Expected: #{expected_path}"
    rescue MiniMagick::Error => error
      raise unless error.message.include?("RMSE")

      distortion = error.message[/\(([\d.]+)\)/, 1].to_f

      assert_operator distortion,
                      :<,
                      threshold,
                      "Images differ too much. Distortion: #{distortion}, " \
                      "Threshold: #{threshold}\n" \
                      "Actual: #{actual_path}\n" \
                      "Expected: #{expected_path}"
    ensure
      $stderr = $original_stderr # rubocop:disable Style/GlobalVars
    end

    def assert_similar_videos(expected_path, actual_path, threshold: 0.01)
      expected_path = Pathname(expected_path)
      actual_path = Pathname(actual_path)

      unless expected_path.file?
        FileUtils.mkdir_p(expected_path.dirname)
        FileUtils.copy(actual_path, expected_path)
        return
      end

      frame_count = count_frames(actual_path)
      middle_frame = frame_count / 2
      last_frame = frame_count - 1

      [0, middle_frame, last_frame].each do |frame|
        actual_frame = extract_frame(actual_path, frame)
        expected_frame = extract_frame(expected_path, frame)

        assert_similar_images(expected_frame, actual_frame, threshold:)
      end
    end

    def count_frames(path)
      command = "ffprobe -v error -select_streams v:0 -count_frames " \
                "-show_entries stream=nb_read_frames " \
                "-of default=nokey=1:noprint_wrappers=1 #{path}"
      `#{command}`.to_i
    end

    def extract_frame(video_path, frame)
      video_name = video_path.basename(".*")
      output_path = tmp_dir.join("frame-#{frame}-#{video_name}.png")

      command = "ffmpeg -i #{video_path} -vf \"select=eq(n\\,#{frame})\" " \
                "-vframes 1 -y #{output_path} 2>/dev/null"
      `#{command}`

      if $CHILD_STATUS.exitstatus.nonzero?
        raise "Failed to extract frame #{frame} from #{video_path}"
      end

      output_path
    end

    def has_audio_stream?(path) #  rubocop:disable Naming/PredicatePrefix
      command = "ffprobe -v error -select_streams a -show_entries " \
                "stream=codec_type -of default=noprint_wrappers=1:nokey=1 " \
                "#{path}"

      audio_streams = `#{command}`.strip

      !audio_streams.empty?
    end

    def assert_no_audio(path)
      refute has_audio_stream?(path), "Expected video to have no audio track"
    end

    def assert_has_audio(path)
      assert has_audio_stream?(path),
             "Expected video to have audio track, but found none"
    end

    def assert_lufs(path, expected:, threshold: 0.2)
      result =
        `ffmpeg -i #{path} -af ebur128 -f null - 2>&1 | grep "I:" | tail -1`
      lufs = result[/I:\s*(-?[\d.]+)/, 1]

      refute_nil lufs, "Could not parse LUFS from ffmpeg output"

      actual = lufs.to_f

      assert_in_delta expected, actual, threshold
    end
  end
end

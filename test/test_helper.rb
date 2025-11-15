# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "screen_kit"

require "minitest/utils"
require "minitest/autorun"

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
      Pathname.new(__dir__).join("fixtures", path)
    end

    def font_path(name)
      ScreenKit
        .root_dir
        .join("screenkit/generators/project/resources/fonts/opensans/#{name}")
    end

    def opensans_extra_bold_path
      font_path("OpenSans-ExtraBold.ttf").to_s
    end

    def opensans_semibold_path
      font_path("OpenSans-SemiBold.ttf").to_s
    end

    def create_tmp_path(ext)
      tmp_dir.join([SecureRandom.hex(10), ext].join("."))
    end

    def assert_similar_images(expected_path, actual_path, threshold: 0.01)
      expected_path = Pathname.new(expected_path)
                              .relative_path_from(Pathname.pwd)
      actual_path = Pathname.new(actual_path)
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
    end
  end
end

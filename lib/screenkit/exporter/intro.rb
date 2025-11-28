# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Intro
      include Shell
      include Utils
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("schemas/refs/intro.json")
      end

      # The intro scene configuration.
      attr_reader :config

      # The title text.
      attr_reader :text

      # The source path lookup instance.
      attr_reader :source

      # The log path.
      attr_reader :log_path

      def initialize(config:, text:, source:, log_path: nil)
        self.class.validate!(config)
        @config = config
        @text = text
        @source = source
        @log_path = log_path
      end

      def logo_config
        @logo_config ||= config[:logo]
      end

      def title_config
        @title_config ||= config[:title]
      end

      def sound_config
        return unless config[:sound]

        @sound_config ||= case config[:sound]
                          when String
                            {path: config[:sound], volume: 1.0}
                          else
                            config[:sound]
                          end
      end

      def logo_path
        return unless logo_config

        @logo_path ||= source.search(logo_config.fetch(:path))
      end

      def sound_path
        return unless sound_config

        @sound_path ||= source.search(sound_config.fetch(:path))
      end

      def background_path
        return unless config[:background]
        return if config[:background].start_with?("#")

        @background_path ||= source.search(config[:background])
      end

      def font_path
        return unless title_config&.[](:font_path)

        @font_path ||= source.search(title_config[:font_path])
      end

      def export(path)
        ffmpeg_params => {inputs:, filters:, maps:}

        cmd = [
          "ffmpeg",
          *inputs,
          "-filter_complex", filters,
          *maps,
          "-c:v", "libx264", "-crf", "0", "-pix_fmt", "yuv444p",
          "-c:a", "flac", "-ac", "1", "-ar", "44100",
          "-shortest",
          "-t", Duration.parse(config[:duration]),
          "-r", 24,
          "-y",
          path
        ]

        run_command(*cmd, log_path:)
      end

      private def ffmpeg_params
        duration = Duration.parse(config[:duration])
        fade_in = Duration.parse(config.fetch(:fade_in, 0.0))
        fade_out = Duration.parse(config.fetch(:fade_out, 0.5))
        fade_out_start = duration - fade_out - 0.1

        # Build filter chain
        inputs = []
        filters = []
        stream_index = 0

        # Background layer
        if background_path&.file?
          if video_file?(background_path)
            extname = background_path.extname
            optimized_path = background_path.sub_ext("_24fps#{extname}")

            if Video.right_fps?(background_path)
              optimized_path = background_path
            end

            unless optimized_path.file?
              Video.new(input_path: background_path).export(optimized_path)
            end

            # Video background
            video_duration = duration(optimized_path)

            # Calculate how many loops we need
            loops_needed = (duration / video_duration).ceil

            inputs += [
              "-stream_loop", (loops_needed - 1).to_s,
              "-i", optimized_path
            ]

            # Scale, crop, then trim to exact duration needed
            filters << "[#{stream_index}:v]scale=1920:1080:" \
                       "force_original_aspect_ratio=increase:flags=lanczos," \
                       "crop=1920:1080," \
                       "trim=end=#{duration}," \
                       "setpts=PTS-STARTPTS[bg]"
          else
            inputs += ["-loop", "1", "-t", duration, "-i", background_path]
            filters << "[#{stream_index}:v]scale=1920:1080:" \
                       "force_original_aspect_ratio=increase:flags=lanczos," \
                       "crop=1920:1080,setpts=PTS-STARTPTS[bg]"
          end
        else
          background = config.fetch(:background, "black")
          inputs += [
            "-f", "lavfi", "-i",
            "color=c=#{background}:s=1920x1080:d=#{duration}"
          ]
          filters << "[#{stream_index}:v]setpts=PTS-STARTPTS[bg]"
        end
        stream_index += 1

        current_layer = "bg"

        # Logo layer (if present)
        if logo_path
          logo_width = logo_config.fetch(:width, 350)
          logo_x = logo_config.fetch(:x, "center")
          logo_y = logo_config.fetch(:y, "center")
          overlay_x = logo_x == "center" ? "(W-w)/2" : logo_x
          overlay_y = logo_y == "center" ? "(H-h)/2" : logo_y

          inputs += ["-loop", "1", "-i", logo_path]
          filters << "[#{stream_index}:v]scale=#{logo_width}:" \
                     "-1:flags=lanczos[logo]"
          filters << "[#{current_layer}][logo]overlay=#{overlay_x}:" \
                     "#{overlay_y}[with_logo]"
          current_layer = "with_logo"
          stream_index += 1
        end

        # Title layer (if present)
        if title_config
          title_x = title_config.fetch(:x, "center")
          title_y = title_config.fetch(:y, "center")
          title_size = title_config.fetch(:size, 72)
          title_color = title_config.fetch(:color, "white")

          # Calculate max width based on x offset
          max_width = if title_x == "center"
                        1720 # 1920 - (2 * 100)
                      else
                        1920 - (2 * title_x.to_i)
                      end

          # Rough estimate characters per line based on font size
          avg_char_width = title_size * 0.7
          max_chars_per_line = (max_width / avg_char_width).floor

          # Auto-wrap text
          wrapped_text = wrap_text(text, max_chars_per_line)

          # Convert position to drawtext coordinates
          drawtext_x = title_x == "center" ? "(w-text_w)/2" : title_x
          drawtext_y = title_y == "center" ? "(h-text_h)/2" : title_y

          # Center align text when x is centered
          text_align = title_x == "center" ? ":text_align=center" : ""

          # Escape special characters in text
          wrapped_text = wrapped_text.gsub("'", "'\\\\\\''").gsub(":", "\\:")

          filters << "[#{current_layer}]drawtext=text='#{wrapped_text}':" \
                     "fontfile=#{font_path}:fontsize=#{title_size}:" \
                     "fontcolor=#{title_color}:x=#{drawtext_x}:" \
                     "y=#{drawtext_y}#{text_align}[with_title]"
          current_layer = "with_title"
        end

        # Apply fades to final video layer
        # Use black for fade color when background is an image file
        fade_color = background_path&.file? ? "black" : background
        filters << "[#{current_layer}]fade=t=in:st=0:d=#{fade_in}:" \
                   "c=#{fade_color},fade=t=out:st=#{fade_out_start}:" \
                   "d=#{fade_out}:c=#{fade_color},setpts=PTS-STARTPTS[fade]"

        # Audio (always generate, silent if no sound configured)
        if sound_path
          inputs += ["-i", sound_path]
          sound_volume = sound_config.fetch(:volume, 1.0)
          filters << "[#{stream_index}:a]apad,atrim=end=#{duration}," \
                     "aresample=async=1,volume=#{sound_volume}[a]"
        else
          # Generate silent audio track
          filters << "anullsrc=r=44100:cl=mono,atrim=end=#{duration}[a]"
        end

        maps = ["-map", "[fade]", "-map", "[a]"]

        {inputs:, filters: filters.join(";"), maps:}
      end

      def wrap_text(text, max_chars_per_line)
        return text if text.lines.size > 1

        words = text.strip.split(/\s+/)
        breaks = []
        current_line = []

        words.each do |word|
          line_size_candidate = current_line.join(" ").length + word.length + 1

          if line_size_candidate <= max_chars_per_line
            current_line << word
          else
            breaks << current_line.join(" ")
            current_line = [word]
          end
        end

        breaks << current_line.join(" ") unless current_line.empty?

        breaks.join("\n")
      end
    end
  end
end

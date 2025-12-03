# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Intro
      using CoreExt

      include Shell
      include Utils
      include ImageMagick
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("schemas/refs/intro.json")
      end

      # The intro scene configuration.
      attr_reader :config

      # The source path lookup instance.
      attr_reader :source

      # The log path.
      attr_reader :log_path

      def initialize(config:, source:, log_path: nil)
        self.class.validate!(config)
        @config = config
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

      def render_elements(overlay_path)
        padding = Spacing.new(hi_res(config.fetch(:padding, 100)))

        hi_res(
          image_width: 1920,
          image_height: 1080,
          content_width: 1920 - (padding.horizontal / 2)
        ) => {
          image_width:,
          image_height:,
          content_width:,
        }

        logo = hi_res({width: 350, x: 0, y: 0}.deep_merge(config[:logo]))
        title = hi_res({size: 144, x: 0, y: 0}.deep_merge(config[:title]))
        url = hi_res({size: 42, x: 0, y: 0}.deep_merge(config[:url]))
        url_height = 0

        logo_intermediary_path = overlay_path.sub_ext("_logo.png")
        title_intermediary_path = overlay_path.sub_ext("_title.png")
        url_intermediary_path = overlay_path.sub_ext("_url.png")

        MiniMagick.convert do |image|
          image << logo_path
          image << "-resize"
          image << "#{logo[:width]}x"
          image << "PNG:#{logo_intermediary_path}"
        end

        title_style = TextStyle.new(source:, **title)
        url_style = TextStyle.new(source:, **url)

        _, _, title_height =
          *render_text_image(path: title_intermediary_path,
                             text: title[:text],
                             style: title_style,
                             width: content_width,
                             type: "caption")

        if url[:text]
          _, _, url_height =
            *render_text_image(path: url_intermediary_path,
                               text: url[:text],
                               style: url_style,
                               width: content_width,
                               type: "caption")
        end

        MiniMagick.convert do |image|
          image << "-size"
          image << "#{image_width}x#{image_height}"
          image << "xc:none"

          image << logo_intermediary_path
          image << "-geometry"
          image << "+#{padding.left}+#{padding.top}"
          image << "-composite"

          offset_y = (image_height - title_height) / 2

          image << title_intermediary_path
          image << "-geometry"
          image << "+#{padding.left}+#{offset_y}"
          image << "-composite"

          offset_y = image_height - padding.bottom - url_height

          if url[:text]
            image << url_intermediary_path
            image << "-geometry"
            image << "+#{padding.left}+#{offset_y}"
            image << "-composite"
          end

          image << "PNG:#{overlay_path}"
        end
      end

      def export(path)
        overlay_path = path.sub_ext(".png")
        render_elements(overlay_path)

        ffmpeg_params(overlay_path) => {inputs:, filters:, maps:}

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

      private def ffmpeg_params(overlay_path)
        duration = Duration.parse(config[:duration])
        fade_in = Duration.parse(config.fetch(:fade_in, 0.0))
        fade_out = Duration.parse(config.fetch(:fade_out, 0.5))
        fade_out_start = duration - fade_out - 0.2

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

        # Overlay layer (if present)
        if overlay_path.file?
          inputs += ["-loop", "1", "-i", overlay_path]
          filters << "[#{stream_index}:v]scale=1920:1080[overlay]"
          filters << "[#{current_layer}][overlay]overlay=0:0[with_overlay]"
          current_layer = "with_overlay"
          stream_index += 1
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

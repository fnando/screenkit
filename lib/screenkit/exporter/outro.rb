# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Outro
      include Shell
      include Utils
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("screenkit/schemas/refs/outro.json")
      end

      # The outro scene configuration.
      attr_reader :config

      # The source path lookup instance.
      attr_reader :source

      def initialize(config:, source:)
        self.class.validate!(config)
        @config = config
        @source = source
      end

      def logo_config
        @logo_config ||= config.fetch(:logo)
      end

      def sound_config
        return unless config[:sound]

        @sound_config ||= case config[:sound]
                          when String
                            {path: config[:sound], volume: 1.0}
                          else
                            config.fetch(:sound)
                          end
      end

      def logo_path
        @logo_path ||= source.search(logo_config.fetch(:path))
      end

      def sound_path
        return unless sound_config

        @sound_path ||= source.search(sound_config.fetch(:path))
      end

      def background_path
        return unless config[:background]
        return if config[:background].to_s.start_with?("#")

        @background_path ||= source.search(config[:background])
      end

      def export(path)
        ffmpeg_params => {inputs:, filters:, maps:}

        cmd = [
          "ffmpeg",
          *inputs,
          "-sws_flags", "lanczos+accurate_rnd+full_chroma_int",
          "-filter_complex", filters,
          *maps,
          "-c:v", "libx264", "-crf", "0", "-pix_fmt", "yuv444p",
          "-c:a", "flac", "-ac", "1", "-ar", "44100",
          "-shortest",
          "-t", config[:duration],
          "-y",
          path
        ]

        run_command(*cmd)
      end

      private def ffmpeg_params
        duration = config[:duration]
        logo_delay = 0.5
        fade_in = config.fetch(:fade_in, 0.5)
        fade_out = config.fetch(:fade_out, 0.5)
        fade_out_start = duration - fade_out - 0.1

        # Build filter chain
        inputs = []
        filters = []
        stream_index = 0

        # Background layer
        if background_path&.file?
          if video_file?(background_path)
            # Video background
            video_duration = duration(background_path)

            # Calculate how many loops we need
            loops_needed = (duration / video_duration).ceil

            inputs += [
              "-stream_loop", (loops_needed - 1).to_s, "-i",
              background_path
            ]

            # Scale, crop, then trim to exact duration needed
            filters << "[#{stream_index}:v]scale=1920:1080:" \
                       "force_original_aspect_ratio=increase:flags=lanczos," \
                       "crop=1920:1080," \
                       "trim=end=#{duration}," \
                       "setpts=PTS-STARTPTS[bg]"
          else
            # Image background
            inputs += ["-loop", "1", "-t", duration, "-i", background_path]
            filters << "[#{stream_index}:v]scale=1920:1080:" \
                       "force_original_aspect_ratio=increase:flags=lanczos," \
                       "crop=1920:1080,setpts=PTS-STARTPTS[bg]"
          end
        else
          # Color background
          background = config.fetch(:background, "black")
          inputs += [
            "-f", "lavfi", "-i",
            "color=c=#{background}:s=1920x1080:d=#{duration}"
          ]
          filters << "[#{stream_index}:v]setpts=PTS-STARTPTS[bg]"
        end
        stream_index += 1

        current_layer = "bg"

        # Logo layer
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

        # Apply fades to final video layer
        # Use black for fade color when background is a file
        fade_color = if background_path&.file?
                       "black"
                     else
                       config.fetch(
                         :background, "black"
                       )
                     end
        filters << "[#{current_layer}]fade=t=in:st=#{logo_delay}:d=#{fade_in}:" \
                   "c=#{fade_color},fade=t=out:st=#{fade_out_start}:" \
                   "d=#{fade_out}:c=#{fade_color},setpts=PTS-STARTPTS[fade]"

        # Audio (always generate, silent if no sound configured)
        if sound_path
          inputs += ["-i", sound_path]
          sound_volume = sound_config.fetch(:volume, 1.0)
          filters << "[#{stream_index}:a]adelay=#{(logo_delay * 1000).to_i}|" \
                     "#{(logo_delay * 1000).to_i}," \
                     "apad,atrim=end=#{duration}," \
                     "aresample=async=1,volume=#{sound_volume}[a]"
        else
          # Generate silent audio track
          filters << "anullsrc=r=44100:cl=mono,atrim=end=#{duration}[a]"
        end

        maps = ["-map", "[fade]", "-map", "[a]"]

        {inputs:, filters: filters.join(";"), maps:}
      end
    end
  end
end

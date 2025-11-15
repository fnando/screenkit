# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Outro
      include Shell
      extend SchemaValidator

      def self.schema_path
        ScreenKit.root_dir.join("screenkit/schemas/refs/outro.json")
      end

      # The outro scene configuration.
      attr_reader :config

      def initialize(config:)
        self.class.validate!(config)
        @config = config
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
        @logo_path ||= Pathname.new(logo_config.fetch(:path))
      end

      def sound_path
        return unless sound_config

        @sound_path ||= Pathname.new(sound_config.fetch(:path))
      end

      def background_path
        return unless config[:background]

        @background_path ||= Pathname.new(config[:background])
      end

      def export(path)
        ffmpeg_params => {inputs:, filters:, maps:}

        cmd = [
          "ffmpeg",
          *inputs,
          "-sws_flags", "lanczos+accurate_rnd+full_chroma_int",
          "-filter_complex", filters,
          *maps,
          "-c:v", "libx264",
          "-pix_fmt", "yuv420p",
          "-color_range", "jpeg"
        ]

        cmd += ["-c:a", "aac", "-ac", "1"] if sound_path

        cmd += [
          "-shortest",
          "-t", config[:duration],
          "-y",
          path
        ]

        run_command(*cmd)
      end

      private def ffmpeg_params
        duration = config[:duration]
        background = config.fetch(:background, "black")
        fade_in = config.fetch(:fade_in, 0.5)
        fade_out = config.fetch(:fade_out, 0.5)
        logo_width = logo_config.fetch(:width, 350)
        fade_out_start = duration - fade_out - 0.1

        # Calculate logo position
        logo_x = logo_config.fetch(:x, "center")
        logo_y = logo_config.fetch(:y, "center")
        overlay_x = logo_x == "center" ? "(W-w)/2" : logo_x
        overlay_y = logo_y == "center" ? "(H-h)/2" : logo_y

        if background_path&.file?
          inputs = [
            "-loop", "1",
            "-t", duration,
            "-i", background_path,
            "-loop", "1",
            "-i", logo_path
          ]
          inputs += ["-i", sound_path] if sound_path

          filters =
            "[0:v]scale=1920:1080:force_original_aspect_ratio=increase:" \
            "flags=lanczos,crop=1920:1080,setpts=PTS-STARTPTS[bg];" \
            "[1:v]scale=#{logo_width}:-1:flags=lanczos,fade=t=in:" \
            "st=0:d=#{fade_in}:alpha=1,fade=t=out:st=#{fade_out_start}:" \
            "d=#{fade_out}:alpha=1[logo];" \
            "[bg][logo]overlay=#{overlay_x}:#{overlay_y}[fade]"

          if sound_path
            sound_volume = sound_config.fetch(:volume, 1.0)
            filters += ";[2:a]apad,atrim=end=#{duration},aresample=async=1," \
                       "volume=#{sound_volume}[a]"
          end

          maps = ["-map", "[fade]"]
          maps += ["-map", "[a]"] if sound_path

          {inputs: inputs, filters: filters, maps: maps}
        else
          inputs = [
            "-f", "lavfi",
            "-i", "color=c=#{background}:s=1920x1080:d=#{duration}",
            "-loop", "1",
            "-i", logo_path
          ]
          inputs += ["-i", sound_path] if sound_path

          filters =
            "[1:v]scale=#{logo_width}:-1:flags=lanczos[logo];" \
            "[0:v][logo]overlay=#{overlay_x}:#{overlay_y}[vid];" \
            "[vid]fade=t=in:st=0:d=#{fade_in}:c=#{background}," \
            "fade=t=out:st=#{fade_out_start}:d=#{fade_out}:c=#{background}," \
            "setpts=PTS-STARTPTS[fade]"

          if sound_path
            sound_volume = sound_config.fetch(:volume, 1.0)
            filters += ";[2:a]apad,atrim=end=#{duration}," \
                       "aresample=async=1,volume=#{sound_volume}[a]"
          end

          maps = ["-map", "[fade]"]
          maps += ["-map", "[a]"] if sound_path

        end

        {inputs:, filters:, maps:}
      end
    end
  end
end

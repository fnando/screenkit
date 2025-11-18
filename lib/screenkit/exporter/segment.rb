# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Segment
      include Shell
      include Utils

      # The path to the content file for this segment.
      # @return [Pathname]
      attr_reader :content_path

      # The episode exporter this segment belongs to.
      # @return [ScreenKit::Exporter::Episode]
      attr_reader :episode

      # The prefix number of the segment file.
      attr_reader :prefix

      def initialize(content_path:, episode:)
        @prefix = content_path.basename.to_s[/^(\d+)/, 1]
        @content_path = content_path
        @episode = episode
      end

      def script_path
        @script_path ||= episode.root_dir.join("scripts", "#{prefix}.txt")
      end

      def video_path
        @video_path ||= episode.output_dir.join("videos", "#{prefix}.mp4")
      end

      def callouts_path
        @callouts_path ||= episode.root_dir.join("callouts/#{prefix}.yml")
      end

      def segment_path
        @segment_path ||= episode.output_dir.join("segments", "#{prefix}.mp4")
      end

      def voiceover_path
        return episode.mute_sound_path unless episode.tts?

        dir = episode.root_dir.join("voiceovers")
        dir.glob("#{prefix}.{#{ContentType.audio.join(',')}}").first ||
          dir.join("#{prefix}.mp3")
      end

      def output_voiceover_path
        episode.output_dir.join("voiceovers").join("#{prefix}.flac")
      end

      def callouts
        @callouts ||= if callouts_path.file?
                        YAML.load_file(callouts_path, symbolize_names: true)
                      else
                        []
                      end
      end

      def export_video
        return if video_path.file? && !episode.options.overwrite

        case content_path.extname.downcase.gsub(/^\./, "")
        when *ContentType.video
          FileUtils.cp(content_type, video_path)
        when *ContentType.image
          Exporter::Image.new(image_path: content_path).export(video_path)
        when *ContentType.demotape
          Exporter::Demotape.new(demotape_path: content_path).export(video_path)
        else
          raise "Unsupported content type: #{content_path.extname}"
        end
      end

      def crossfade_duration
        episode.scenes.fetch(:segment).fetch(:crossfade_duration, 0.5)
      end

      def merge_audio_and_video
        # Get video duration
        video_duration = duration(video_path)

        # Get audio duration
        audio_duration = duration(output_voiceover_path)

        # Calculate the content duration and extend by crossfade duration
        content_duration = [video_duration, audio_duration].max
        final_duration = content_duration + crossfade_duration

        # # Calculate padding needed for audio (content + silence for crossfade)
        audio_pad_samples = ((final_duration - audio_duration) * 44_100).to_i

        # Calculate video padding (content + cloned frame for crossfade)
        video_pad_duration = final_duration - video_duration

        # The raw video and voiceover
        inputs = ["-i", video_path, "-i", output_voiceover_path]

        filters = [
          "[0:v]tpad=stop_mode=clone:stop_duration=#{video_pad_duration}[v0]"
        ]

        audio_mix_inputs = ["[1:a]"]
        animation_duration = 0.2
        video_width = 1920
        video_height = 1080

        callouts.each_with_index do |callout, index|
          type = callout[:type].to_sym
          callout_config = episode.project_config.callouts[type]
          in_sound = Sound.new(input: callout_config[:in_transition][:sound],
                               source: episode.source)
          out_sound = Sound.new(input: callout_config[:out_transition][:sound],
                                source: episode.source)

          margin_top, margin_right, margin_bottom, margin_left =
            (Array(callout_config[:margin] || 0) * 4).take(4)
          starts_at = callout[:starts_at]
          anchor_x, anchor_y = *callout_config[:anchor]
          ends_at = starts_at + callout[:duration]
          callout_image_path = episode.output_dir.join("callouts",
                                                       "#{prefix}-#{index}.png")
          image = MiniMagick::Image.open(callout_image_path)
          image_width = image.width / 2
          image_height = image.height / 2
          y = case anchor_y
              when "bottom"
                video_height - image_height - margin_bottom
              when "top"
                margin_top
              when "center"
                (video_height / 2) - (image_height / 2)
              else
                anchor_y + margin_top
              end
          x = case anchor_x
              when "left"
                margin_left
              when "right"
                video_width - image_width - margin_right
              when "center"
                (video_height / 2) - (image_height / 2)
              else
                anchor_x + margin_left
              end

          inputs += [
            "-loop", "1",
            "-t", callout.fetch(:duration),
            "-i", callout_image_path,

            # Add sound for transition in
            "-i", in_sound.path,

            # Add sound for transition out
            "-i", out_sound.path
          ]

          input_stream = "v#{index}"
          output_stream = "v#{index + 1}"
          callout_index = 2 + (index * 3)

          animation_filters = AnimationFilters.new(
            video_duration:,
            callout_index:,
            input_stream:,
            output_stream:,
            index:,
            starts_at:,
            ends_at:,
            x:,
            y:,
            animation_duration:,
            image_width:,
            image_height:
          ).fade

          filters.concat(animation_filters[:video])

          # Delay and mix callout sounds
          in_index = callout_index + 1
          out_index = callout_index + 2

          filters << "[#{in_index}:a]volume=#{in_sound.volume}," \
                     "adelay=#{(starts_at * 1000).to_i}|" \
                     "#{(starts_at * 1000).to_i}[in_#{index}]"
          filters << "[#{out_index}:a]volume=#{out_sound.volume}," \
                     "adelay=#{(animation_filters[:out_start] * 1000).to_i}|" \
                     "#{(animation_filters[:out_start] * 1000).to_i}" \
                     "[out_#{index}]"

          audio_mix_inputs << "[in_#{index}]"
          audio_mix_inputs << "[out_#{index}]"
        end

        # Mix all audio streams (voiceover + all sounds)
        filters << "#{audio_mix_inputs.join}amix=inputs=" \
                   "#{audio_mix_inputs.size}:duration=longest:normalize=0" \
                   "[mixed_audio]"
        filters << "[mixed_audio]aresample=async=1,apad=pad_len=" \
                   "#{audio_pad_samples}[a]"

        filter_complex = filters.join(";")

        cmd = [
          "ffmpeg",
          *inputs,
          "-filter_complex",
          filter_complex,
          "-map", "[v#{callouts.size}]",
          "-map", "[a]",
          "-c:a", "flac", "-ac", "1", "-ar", "44100",
          "-c:v", "libx264", "-crf", "0", "-pix_fmt", "yuv444p",
          "-y",
          segment_path
        ]

        run_command(*cmd)
      end

      def export_voiceover
        create_voiceover
        normalize_voiceover
      end

      def normalize_voiceover
        run_command "ffmpeg-normalize",
                    voiceover_path,
                    "-f",
                    "-o", output_voiceover_path,
                    "-nt", "ebu",
                    "-t", "-18",
                    "-c:a", "flac", "-ac", "1", "-ar", "44100"
      end

      def create_voiceover
        return if voiceover_path&.file? && !episode.options.overwrite
        return unless script_path.file?
        return unless episode.tts?

        FileUtils.mkdir_p(voiceover_path.dirname)

        episode.tts_engine.generate(
          text: script_path.read,
          output_path: voiceover_path
        )
      end
    end
  end
end

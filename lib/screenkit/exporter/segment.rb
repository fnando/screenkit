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
        return episode.mute_sound_path unless episode.tts_available?

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

      def export_video(log_path:)
        return if video_path.file? && !overwrite_content?

        log_path = format(log_path.to_s, prefix:) if log_path

        case content_path.extname.downcase.gsub(/^\./, "")
        when *ContentType.video
          Exporter::Video
            .new(input_path: content_path, log_path:)
            .export(video_path)
        when *ContentType.image
          Exporter::Image
            .new(image_path: content_path, log_path:)
            .export(video_path)
        when *ContentType.demotape
          Exporter::Demotape
            .new(
              demotape_path: content_path,
              log_path:,
              options: episode.demotape_options
            ).export(video_path)
        else
          raise "Unsupported content type: #{content_path.extname}"
        end
      end

      def crossfade_duration
        Duration.parse(
          episode.scenes.fetch(:segment).fetch(:crossfade_duration, 0.5)
        )
      end

      def merge_audio_and_video(log_path:)
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
        current_input_index = 2 # Start after video (0) and voiceover (1)

        callouts.each_with_index do |callout, index|
          current_input_index = process_callout(
            callout:,
            index:,
            content_duration:,
            animation_duration:,
            inputs:,
            filters:,
            audio_mix_inputs:,
            current_input_index:
          )
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
          "-t", final_duration,
          "-r", 24,
          "-c:a", "flac", "-ac", "1", "-ar", "44100",
          "-c:v", "libx264", "-crf", "0", "-pix_fmt", "yuv444p",
          "-y",
          segment_path
        ]

        run_command(*cmd, log_path: create_log_path(log_path, __method__))
      end

      def export_voiceover(log_path:)
        create_voiceover(log_path: create_log_path(log_path))
        normalize_voiceover(
          log_path: create_log_path(log_path, :normalize)
        )
      end

      def normalize_voiceover(log_path:)
        run_command "ffmpeg-normalize",
                    voiceover_path,
                    "-f",
                    "-o", output_voiceover_path,
                    "-nt", "ebu",
                    "-t", "-18",
                    "-c:a", "flac", "-ac", "1", "-ar", "44100",
                    log_path:
      end

      def script_content
        @script_content ||= script_path.read if script_path.file?
      end

      def overwrite_voiceover?
        episode.options.overwrite || episode.options.overwrite_voiceover
      end

      def overwrite_content?
        episode.options.overwrite || episode.options.overwrite_content
      end

      def create_voiceover(log_path:)
        return if voiceover_path&.file? && !overwrite_voiceover?
        return unless script_path.file?
        return unless episode.tts_available?

        FileUtils.mkdir_p(voiceover_path.dirname)

        episode.tts_engine.generate(
          text: script_content,
          output_path: voiceover_path,
          log_path:
        )
      end

      def create_log_path(path, tag = nil)
        return path unless path

        path = path.sub_ext("-#{tag.to_s.tr('_', '-')}.txt") if tag

        format(path.to_s, prefix:) if path
      end

      def process_callout(
        callout:,
        index:,
        content_duration:,
        animation_duration:,
        inputs:,
        filters:,
        audio_mix_inputs:,
        current_input_index:
      )
        type = callout[:type].to_sym
        callout_config = episode.callout_styles[type]
        in_sound = Sound.new(input: callout_config[:in_transition][:sound],
                             source: episode.source)
        out_sound = Sound.new(input: callout_config[:out_transition][:sound],
                              source: episode.source)

        starts_at = TimeFormatter.parse(callout[:starts_at])
        max_duration = [content_duration - 0.2, 0].max
        duration = Duration.parse(callout[:duration])
                           .clamp(0, max_duration)
                           .round(half: :down)
        ends_at = starts_at + duration
        callout_duration = ends_at - starts_at

        callout_path = find_callout_path(index)
        video_callout = video_callout?(callout_path)
        has_video_audio = has_audio?(callout_path)

        callout_width, callout_height = image_size(callout_path)
        x, y = calculate_callout_position(
          video_callout:,
          callout_config:,
          callout_width:,
          callout_height:
        )

        callout_index, current_input_index = add_callout_inputs(
          inputs:,
          current_input_index:,
          callout_path:,
          video_callout:,
          has_video_audio:,
          duration:
        )

        in_sound_index, out_sound_index, current_input_index =
          add_transition_sound_inputs(
            inputs:,
            current_input_index:,
            video_callout:,
            in_sound:,
            out_sound:
          )

        animation_filters = add_video_filters(
          filters:,
          index:,
          callout_index:,
          callout_config:,
          video_callout:,
          content_duration:,
          starts_at:,
          ends_at:,
          x:,
          y:,
          animation_duration:,
          callout_width:,
          callout_height:
        )

        add_audio_filters(
          filters:,
          audio_mix_inputs:,
          index:,
          callout_index:,
          video_callout:,
          has_video_audio:,
          starts_at:,
          callout_duration:,
          in_sound:,
          out_sound:,
          in_sound_index:,
          out_sound_index:,
          animation_filters:
        )

        current_input_index
      end

      def find_callout_path(index)
        callout_path = episode.output_dir.join("callouts").glob(
          "#{prefix}-#{index}.{png,#{ContentType.video.join(',')}}"
        ).first

        return callout_path if callout_path

        raise "Callout file not found for #{prefix}-#{index}"
      end

      def video_callout?(callout_path)
        ContentType.video.include?(callout_path.extname.delete_prefix("."))
      end

      def calculate_callout_position(
        video_callout:,
        callout_config:,
        callout_width:,
        callout_height:
      )
        # For video callouts, ignore anchor/margin and position at 0,0
        # (assumes videos are already properly sized and positioned)
        if video_callout
          [0, 0]
        else
          calculate_position(
            anchor: Anchor.new(callout_config[:anchor]),
            margin: Spacing.new(callout_config[:margin] || 0),
            width: callout_width,
            height: callout_height
          )
        end
      end

      def add_callout_inputs(
        inputs:,
        current_input_index:,
        callout_path:,
        video_callout:,
        has_video_audio:,
        duration:
      )
        callout_index = current_input_index

        if video_callout
          # Don't use -t for videos, let them play naturally
          inputs << "-i" << callout_path
          current_input_index += 1

          # Add mute audio if video has no audio
          unless has_video_audio
            inputs << "-t" << duration << "-i" << episode.mute_sound_path
            current_input_index += 1
          end
        else
          inputs << "-loop" << "1" << "-t" << duration << "-i" << callout_path
          current_input_index += 1
        end

        [callout_index, current_input_index]
      end

      def add_transition_sound_inputs(
        inputs:,
        current_input_index:,
        video_callout:,
        in_sound:,
        out_sound:
      )
        # Add transition sounds (only for non-video callouts)
        return [nil, nil, current_input_index] if video_callout

        in_sound_index = current_input_index
        inputs << "-i" << in_sound.path
        current_input_index += 1

        out_sound_index = current_input_index
        inputs << "-i" << out_sound.path
        current_input_index += 1

        [in_sound_index, out_sound_index, current_input_index]
      end

      def add_video_filters(
        filters:,
        index:,
        callout_index:,
        callout_config:,
        video_callout:,
        content_duration:,
        starts_at:,
        ends_at:,
        x:,
        y:,
        animation_duration:,
        callout_width:,
        callout_height:
      )
        input_stream = "v#{index}"
        output_stream = "v#{index + 1}"
        animation_method = video_callout ? :video : callout_config[:animation]

        animation_filters = AnimationFilters.new(
          content_duration:,
          callout_index:,
          input_stream:,
          output_stream:,
          index:,
          starts_at:,
          ends_at:,
          x:,
          y:,
          animation_duration:,
          image_width: callout_width,
          image_height: callout_height
        ).send(animation_method)

        filters.concat(animation_filters[:video])

        animation_filters
      end

      def add_audio_filters(
        filters:,
        audio_mix_inputs:,
        index:,
        callout_index:,
        video_callout:,
        has_video_audio:,
        starts_at:,
        callout_duration:,
        in_sound:,
        out_sound:,
        in_sound_index:,
        out_sound_index:,
        animation_filters:
      )
        # Mix video audio if present
        if video_callout && has_video_audio
          filters <<
            "[#{callout_index}:a]atrim=end=#{callout_duration}," \
            "asetpts=PTS-STARTPTS,adelay=#{(starts_at * 1000).to_i}|" \
            "#{(starts_at * 1000).to_i}[video_audio_#{index}]"
          audio_mix_inputs << "[video_audio_#{index}]"
        end

        # For non-video callouts, add transition sounds
        return if video_callout

        filters << "[#{in_sound_index}:a]volume=#{in_sound.volume}," \
                   "adelay=#{(starts_at * 1000).to_i}|" \
                   "#{(starts_at * 1000).to_i}[in_#{index}]"
        filters << "[#{out_sound_index}:a]volume=#{out_sound.volume}," \
                   "adelay=#{(animation_filters[:out_start] * 1000).to_i}|" \
                   "#{(animation_filters[:out_start] * 1000).to_i}" \
                   "[out_#{index}]"

        audio_mix_inputs << "[in_#{index}]"
        audio_mix_inputs << "[out_#{index}]"
      end
    end
  end
end

# frozen_string_literal: true

module ScreenKit
  module Exporter
    class Episode
      using CoreExt
      include Utils
      include Shell

      # Glob pattern to match content files.
      # Each file will be used as a segment in the episode.
      CONTENT_PATTERN = "content/**/*.{#{ContentType.all.join(',')}}".freeze

      # The project configuration, usually the root's screenkit.yml file.
      # @return [ScreenKit::Config::Project]
      attr_reader :project_config

      # The episode configuration, usually the episode's config.yml file.
      # @return [ScreenKit::Config::Episode]
      attr_reader :config

      # The export options.
      # @return [Hash{Symbol => Object}]
      attr_reader :options

      # A mutex for thread-safe operations.
      attr_reader :mutex

      def initialize(project_config:, config:, options:)
        @project_config = project_config
        @config = config
        @options = options
        @mutex = Mutex.new
      end

      def tts?
        config.tts || project_config.tts
      end

      def tts_options
        (config.tts || {}).merge(project_config.tts || {})
      end

      def tts_engine
        @tts_engine ||= TTS.const_get(
          tts_options[:engine].camelize
        ).new(**tts_options.except(:engine))
      end

      # Logs a message to the shell with a specific category.
      #
      # @param category [Symbol] The category of the log message
      # (e.g., :info, :error).
      # @param message [String] The log message, which can include format
      # placeholders.
      # @param ** [Hash{Symbol => Object}] Additional keyword arguments to
      # format the message.
      def log(category, message, color: :magenta, **)
        shell.say_status(category, format(message.to_s, **), color)
      end

      def log_elapsed(message, elapsed)
        log(
          :info,
          message,
          elapsed: shell.set_color(format("%.2fs", elapsed), :blue)
        )
      end

      def export
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        prelude
        cleanup_output_dir
        create_output_dir
        export_intro
        export_outro
        export_voiceovers
        export_videos
        export_callouts
        create_segments
        merge_segments

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        log_elapsed("Exported episode in %{elapsed}", elapsed)
      ensure
        spinner.stop
      end

      def export_callouts
        callouts = filtered_segments.flat_map do |segment|
          segment.callouts.map { {prefix: segment.prefix, callouts: it} }
        end

        elapsed = ParallelProcessor.new(
          spinner:,
          list: callouts,
          message: "Exporting callouts (%{progress}/%{count})"
        ).run do |item, index|
          type = item[:callouts].fetch(:type).to_sym
          callout_style = project_config
                          .callouts
                          .fetch(type)
                          .merge(item[:callouts].except(:starts_at, :duration))
          callout_path = output_dir
                         .join("callouts", "#{item[:prefix]}-#{index}.png")
          Callout.new(source:, **callout_style, output_path: callout_path)
                 .render
        end

        log_elapsed("Created callouts in %{elapsed}", elapsed)
      end

      def export_voiceovers
        elapsed = ParallelProcessor.new(
          spinner:,
          list: filtered_segments,
          message: "Exporting voiceovers (%{progress}/%{count})"
        ).run(&:export_voiceover)

        log_elapsed("Generated voiceover in %{elapsed}", elapsed)
      end

      def export_videos
        elapsed = ParallelProcessor.new(
          spinner:,
          list: filtered_segments,
          message: "Exporting videos (%{progress}/%{count})"
        ).run(&:export_video)

        log_elapsed("Exported videos in %{elapsed}", elapsed)
      end

      def create_segments
        elapsed = ParallelProcessor.new(
          spinner:,
          list: filtered_segments,
          message: "Merging audio and video (%{progress}/%{count})"
        ).run(&:merge_audio_and_video)

        log_elapsed("Created segments in %{elapsed}", elapsed)
      end

      def merge_segments
        spinner.update("Merging segments into final episode…")
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        crossfade_duration = scenes.dig(:segment, :crossfade_duration) || 0.5

        # Build input files list: intro, segments, outro
        all_videos = [
          intro_path,
          *output_dir.glob("segments/**/*.mp4"),
          outro_path
        ]

        backtrack_adjustment = 1.0 / backtrack.volume
        backtrack_fade_volume = if tts?
                                  0.15 * backtrack_adjustment
                                else
                                  1.0
                                end
        backtrack_full_volume = backtrack.volume

        # Build ffmpeg inputs
        inputs = all_videos.flat_map {|path| ["-i", path] }
        inputs += ["-i", backtrack.path]

        # Build xfade filter chain for video with crossfades
        video_filters = []
        audio_filters = []
        offset = 0
        target_fps = 24.0

        all_videos.each_with_index do |video_path, index|
          # Get original video duration and fps
          video_duration = duration(video_path)
          video_fps = fps(video_path)

          # Adjust duration for fps conversion
          adjusted_duration = video_duration * (video_fps / target_fps)
          prev_label = index == 1 ? "v0" : "vx#{index - 2}"

          video_filters <<
            "[#{index}:v]fps=#{target_fps},setpts=PTS-STARTPTS[v#{index}]"

          if index.zero?
            # First video (intro)
            audio_filters << "[#{index}:a]asetpts=PTS-STARTPTS[a#{index}]"
            offset = adjusted_duration - crossfade_duration
          elsif index == all_videos.size - 1
            # Last video (outro) - xfade from previous
            # Ensure the previous video is long enough for the xfade by padding
            # if needed
            pad_duration = offset + crossfade_duration
            video_filters << "[#{prev_label}]tpad=stop_mode=clone:" \
                             "stop_duration=#{pad_duration}" \
                             "[#{prev_label}_padded]"
            video_filters << "[#{prev_label}_padded][v#{index}]" \
                             "xfade=transition=fade:" \
                             "duration=#{crossfade_duration}:" \
                             "offset=#{offset}[vfinal]"
            audio_filters << "[#{index}:a]adelay=#{(offset * 1000).to_i}|" \
                             "#{(offset * 1000).to_i}[a#{index}]"
          else
            video_filters << "[#{prev_label}][v#{index}]" \
                             "xfade=transition=fade:" \
                             "duration=#{crossfade_duration}:" \
                             "offset=#{offset}[vx#{index - 1}]"
            audio_filters << "[#{index}:a]adelay=#{(offset * 1000).to_i}|" \
                             "#{(offset * 1000).to_i}[a#{index}]"
            offset += adjusted_duration - crossfade_duration
          end
        end

        # Concatenate all audio tracks
        audio_inputs = Array.new(all_videos.size) {|i| "[a#{i}]" }.join
        audio_filters << "#{audio_inputs}amix=inputs=#{all_videos.size}:" \
                         "duration=longest:normalize=0[mixed]"

        # Apply volume fade to backtrack:
        # 1. Starts at backtrack_full_volume during intro
        # 2. Fades to backtrack_fade_volume over 1s, overlapping first segment by 25%
        # 3. Fades out to 0 over 1s at the end of the last segment before outro
        intro_duration = duration(all_videos.first)
        fade_in_duration = 1.0
        # Start fade 75% before intro ends, finish 25% into first segment
        fade_in_start = intro_duration - (fade_in_duration * 0.75)
        fade_in_end = intro_duration + (fade_in_duration * 0.25)

        # Calculate total duration up to end of last segment
        total_duration = 0
        all_videos[0..-2].each_with_index do |video_path, index|
          video_duration = duration(video_path)
          video_fps = fps(video_path)
          adjusted_duration = video_duration * (video_fps / target_fps)

          if index.zero?
            total_duration = adjusted_duration - crossfade_duration
          else
            total_duration += adjusted_duration - crossfade_duration
          end
        end

        fade_out_duration = 1.0
        fade_out_start = total_duration - fade_out_duration

        audio_filters << "[#{all_videos.size}:a]" \
                         "volume='if(lt(t,#{fade_in_start})," \
                         "#{backtrack_full_volume},if(lt(t,#{fade_in_end})," \
                         "#{backtrack_full_volume}-" \
                         "(#{backtrack_full_volume}-" \
                         "#{backtrack_fade_volume})*(t-#{fade_in_start})/" \
                         "#{fade_in_duration},if(lt(t,#{fade_out_start})," \
                         "#{backtrack_fade_volume}," \
                         "if(lt(t,#{total_duration})," \
                         "#{backtrack_fade_volume}*(#{total_duration}-t)/" \
                         "#{fade_out_duration},0))))':eval=" \
                         "frame[backtrack_faded]"

        # Mix with backtrack
        audio_filters << "[mixed][backtrack_faded]amix=inputs=2:" \
                         "duration=first:normalize=0[afinal]"

        filter_complex = (video_filters + audio_filters).join(";")

        command = [
          "ffmpeg",
          *inputs,
          "-filter_complex",
          filter_complex,
          "-map", "[vfinal]",
          "-map", "[afinal]",
          "-c:v", "libx264", "-crf", "0", "-pix_fmt", "yuv444p",
          "-c:a", "aac",
          "-b:a", "320k",
          "-ar", "44100",
          "-y",
          output_video_path
        ]

        run_command(*command)

        spinner.stop

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        log_elapsed("Merged videos in %{elapsed}", elapsed)

        log(
          :info,
          "Exported video to %{path}",
          path: shell.set_color(relative_path(output_video_path), :green)
        )
      end

      # Logs initial information about the episode export process.
      def prelude
        log(
          :info,
          "Project root dir: %{dir}",
          dir: shell.set_color(relative_path(project_root_dir), :blue)
        )
        log(
          :info,
          "Episode root dir: %{dir}",
          dir: shell.set_color(relative_path(root_dir), :blue)
        )

        unless tts?
          log(
            :info,
            shell.set_color("Voiceover is currently disabled", :red),
            color: :red
          )
        end

        filtered_count = filtered_segments.count
        count = segments.count

        message = if filtered_count == count && options.match_segment
                    "Matching all %{count} segments with %{regex}"
                  elsif filtered_count == count
                    "Matching all %{count} segments"
                  else
                    "Matching %{filtered_count} out of %{count} segments " \
                      "with %{regex}"
                  end

        log(
          :info,
          message,
          filtered_count: shell.set_color(filtered_count, :blue),
          count: shell.set_color(count, :blue),
          regex: shell.set_color(match_regex.source, :yellow)
        )
      end

      def create_output_dir
        FileUtils.mkdir_p([
          output_dir.join("segments").to_s,
          output_dir.join("scenes").to_s,
          output_dir.join("logs").to_s,
          output_dir.join("voiceovers").to_s,
          output_dir.join("callouts").to_s,
          output_dir.join("videos").to_s
        ])
      end

      def cleanup_output_dir
        FileUtils.rm_rf(output_dir.join("logs").children)
        FileUtils.rm_rf(output_dir.join("voiceovers").children)
        spinner.stop
      end

      def output_dir
        @output_dir ||= Pathname(
          format(
            options.output_dir || project_config.output_dir.to_s,
            episode_dirname: root_dir.basename
          )
        ).expand_path
      end

      def intro_path
        @intro_path ||= output_dir.join("scenes/intro.mp4")
      end

      def outro_path
        @outro_path ||= output_dir.join("scenes/outro.mp4")
      end

      def export_intro
        time, _ = elapsed do
          spinner.update("Exporting intro…")

          intro_config = scenes.fetch(:intro)

          Intro.new(config: intro_config, text: config.title, source:)
               .export(intro_path)

          spinner.stop
        end

        log_elapsed("Exported intro in %{elapsed}", time)
      end

      def export_outro
        time, _ = elapsed do
          spinner.update("Exporting outro…")

          outro_config = scenes.fetch(:outro)
          Outro.new(config: outro_config, source:).export(outro_path)
          spinner.stop
        end

        log_elapsed("Exported outro in %{elapsed}", time)
      end

      def spinner
        @spinner ||= Spinner.new
      end

      def source
        @source ||= PathLookup.new(*resources_dir)
      end

      def shell
        @shell ||= Thor::Shell::Color.new
      end

      def scenes
        @scenes ||= project_config.scenes.merge(config.scenes)
      end

      def project_root_dir
        @project_root_dir ||= Pathname(root_dir.parent.parent).expand_path
      end

      def root_dir
        @root_dir ||= Pathname(options.dir).expand_path
      end

      def resources_dir
        @resources_dir ||= project_config.resources_dir.map do |dir|
          path = dir
          path = File.expand_path(dir) if dir.start_with?("~")
          path = Pathname(format(path, episode_dir: root_dir))
          path = Pathname.pwd.join(path) unless path.absolute?
          path
        end
      end

      def output_video_path
        @output_video_path ||= output_dir.join("#{root_dir.basename}.mp4")
      end

      def mute_sound_path
        @mute_sound_path ||= ScreenKit.root_dir.join(
          "screenkit/resources/mute.mp3"
        )
      end

      def backtrack
        @backtrack ||=
          if config.backtrack
            Sound.new(input: config.backtrack, source:)
          elsif project_config.backtrack
            Sound.new(input: project_config.backtrack, source:)
          else
            Sound.new(input: mute_sound_path, source:)
          end
      end

      def segments
        @segments ||= root_dir
                      .glob(CONTENT_PATTERN)
                      .map { Segment.new(content_path: it, episode: self) }
      end

      def match_regex
        @match_regex ||= Regexp.new(options.match_segment || ".*")
      end

      # Returns the segments filtered based on the `match_segment` option.
      # @return [Array<ScreenKit::Exporter::Segment>]
      def filtered_segments
        @filtered_segments ||= segments.select do |segment|
          segment.content_path.basename.to_s.match?(match_regex)
        end
      end
    end
  end
end

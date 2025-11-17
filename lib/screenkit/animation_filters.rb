# frozen_string_literal: true

module ScreenKit
  class AnimationFilters
    attr_reader :callout_index, :input_stream, :output_stream, :index,
                :starts_at, :ends_at, :x, :y, :animation_duration,
                :video_duration, :image_width, :image_height

    def initialize(
      callout_index:,
      input_stream:,
      output_stream:,
      index:,
      starts_at:,
      ends_at:,
      x:,
      y:,
      animation_duration:,
      video_duration:,
      image_width:,
      image_height:
    )
      @callout_index = callout_index
      @input_stream = input_stream
      @output_stream = output_stream
      @index = index
      @starts_at = starts_at
      @ends_at = ends_at
      @x = x
      @y = y
      @animation_duration = animation_duration
      @video_duration = video_duration
      @image_width = image_width
      @image_height = image_height
    end

    def fade
      out_start = ends_at - animation_duration

      # If ends_at would go past video duration, shorten it
      adjusted_ends_at = ends_at > video_duration ? ends_at - 0.1 : ends_at

      callout_duration = adjusted_ends_at - starts_at
      fade_out_start = callout_duration - animation_duration
      filters = []

      # Scale callout and apply fade in and fade out
      # Fade in starts at 0, fade out starts at
      # (callout_duration - animation_duration)
      filters <<
        "[#{callout_index}:v]scale=#{image_width}:#{image_height},fade=t=in:" \
        "st=0:d=#{animation_duration}:alpha=1,fade=t=out:" \
        "st=#{fade_out_start}:d=#{animation_duration}:alpha=1" \
        "[callout#{index}_faded]"

      # Use setpts to delay the callout's presentation timestamp to sync with
      # starts_at, then overlay it
      filters <<
        "[callout#{index}_faded]setpts=PTS+#{starts_at}/TB" \
        "[callout#{index}_delayed]"
      filters <<
        "[#{input_stream}][callout#{index}_delayed]overlay=x=#{x}:y=#{y}" \
        "[#{output_stream}]"

      {
        video: filters,
        out_start: out_start
      }
    end

    def slide
      out_start = ends_at - animation_duration
      filters = []

      # Scale and split callout for blur effect
      filters << "[#{callout_index}:v]scale=#{image_width}:" \
                 "#{image_height}[callout#{index}_base]"
      filters << "[callout#{index}_base]split=3[callout#{index}_blur_in]" \
                 "[callout#{index}_sharp][callout#{index}_blur_out]"

      # Create blurred versions for motion
      filters <<
        "[callout#{index}_blur_in]boxblur=20:1[callout#{index}_blurred_in]"
      filters <<
        "[callout#{index}_blur_out]boxblur=20:1[callout#{index}_blurred_out]"

      # Overlay blurred version during slide in
      filters <<
        "[#{input_stream}][callout#{index}_blurred_in]overlay=x=" \
        "'if(lt(t,#{starts_at + animation_duration}),-W+((t-#{starts_at})*" \
        "(W+#{x})/#{animation_duration}),#{x})':y=#{y}:enable=" \
        "'between(t,#{starts_at},#{starts_at + animation_duration})'" \
        "[#{output_stream}_in]"

      # Overlay sharp version while visible
      filters <<
        "[#{output_stream}_in][callout#{index}_sharp]overlay=x=#{x}:y=#{y}:" \
        "enable='between(t,#{starts_at + animation_duration},#{out_start})'" \
        "[#{output_stream}_hold]"

      # Overlay blurred version during slide out (to the left)
      filters <<
        "[#{output_stream}_hold][callout#{index}_blurred_out]overlay=x=" \
        "'if(lt(t,#{ends_at}),#{x}-((t-#{out_start})*(W+#{x})/" \
        "#{animation_duration}),-W)':y=#{y}:enable='between(t,#{out_start}," \
        "#{ends_at})'[#{output_stream}]"

      {video: filters, out_start:}
    end
  end
end

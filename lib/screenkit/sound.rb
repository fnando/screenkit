# frozen_string_literal: true

module ScreenKit
  class Sound
    # The requested sound file path.
    # @return [Pathname]
    attr_reader :path

    # The volume level for the sound.
    # @return [Float]
    attr_reader :volume

    # Initializes a new Sound instance.
    #
    # @param input [Pathname|FalseClass|Hash] The sound configuration. It will
    # be denormalized to all the proper attributes.
    # @return [void]
    def initialize(input:, source:)
      @volume = 1.0

      case input
      when FalseClass, nil
        @path = ScreenKit.root_dir.join("screenkit/resources/mute.mp3")
      when Hash
        {path: nil, volume: 1.0}.merge(input) => {path:, volume:}
        @path = Pathname(path)
        @volume = volume
      else
        @path = Pathname(input)
      end

      return if @path.absolute?
      return if @path.file?

      candidate = source.search(@path)

      @path = if candidate.file?
                candidate
              else
                candidate.glob("**/*.{#{ContentType.audio.join(',')}}").sample
              end
    end
  end
end

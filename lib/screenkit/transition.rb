# frozen_string_literal: true

module ScreenKit
  class Transition
    attr_reader :duration, :sound

    def initialize(duration:, sound:)
      @duration = duration
      @sound = sound
    end

    def as_json(*)
      {duration:, sound:}
    end
  end
end

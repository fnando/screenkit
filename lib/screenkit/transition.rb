# frozen_string_literal: true

module ScreenKit
  class Transition
    attr_reader :duration, :animation, :sound

    def initialize(duration:, animation:, sound:)
      @duration = duration
      @animation = animation
      @sound = sound
    end
  end
end

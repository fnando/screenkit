# frozen_string_literal: true

module ScreenKit
  class Spinner
    attr_reader :phrase

    def initialize(phrases: [])
      @phrases = phrases
      @shell = Thor::Shell::Color.new
      @phrase = @phrases.sample
      @spinner = create_spinner
      update(@phrase)
    end

    def create_spinner
      TTY::Spinner.new(
        "           :spinner  :title",
        frames: [
          @shell.set_color("◉", :white),
          @shell.set_color("◎", :white),
          @shell.set_color("∙", :white)
        ],
        interval: 3,
        clear: true,
        hide_cursor: true
      ).tap(&:auto_spin)
    end

    def update(phrase)
      @spinner ||= create_spinner
      @spinner.update(title: @shell.set_color(phrase, :white))
    end

    def stop
      @spinner&.stop
      @spinner = nil
    end
  end
end

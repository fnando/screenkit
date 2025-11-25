# frozen_string_literal: true

module ScreenKit
  module ContentType
    def self.video = %w[mp4 webm mov]
    def self.audio = %w[mp3 wav m4a aac aiff]
    def self.image = %w[gif jpg jpeg png tiff]
    def self.demotape = %w[tape]

    def self.all = video + image + demotape
  end
end

# frozen_string_literal: true

require "mini_magick"

module ScreenKit
  class Callout
    module Styles
      class Social < Base
        attr_reader :text, :label, :icon, :label_style, :text_style,
                    :background_color

        LABEL_STYLE = {
          color: "#ffffff88",
          size: 24,
          font_path: "open-sans/OpenSans-ExtraBold.ttf"
        }.freeze

        TEXT_STYLE = {
          color: "#ffffff",
          size: 50,
          font_path: "open-sans/OpenSans-ExtraBold.ttf"
        }.freeze

        def self.presets
          @presets ||= {
            instagram: {
              label: "INSTAGRAM",
              icon: {
                path: "callout_styles/social/instagram.png",
                background_color: "#C13684"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#693050"
            },

            spotify: {
              label: "SPOTIFY",
              icon: {
                path: "callout_styles/social/spotify.png",
                background_color: "#1cd760"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#205C36"
            },

            bsky: {
              label: "BSKY",
              icon: {
                path: "callout_styles/social/bsky.png",
                background_color: "#0085FF"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#004483"
            },

            linkedin: {
              label: "LINKEDIN",
              icon: {
                path: "callout_styles/social/linkedin.png",
                background_color: "#007EBB"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#00486A"
            },

            dribbble: {
              label: "DRIBBBLE",
              icon: {
                path: "callout_styles/social/dribbble.png",
                background_color: "#EC4989"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#7A2245"
            },

            tiktok: {
              label: "TIKTOK",
              icon: {
                path: "callout_styles/social/tiktok.png",
                background_color: "#000000"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#252525"
            },

            youtube: {
              label: "YOUTUBE",
              icon: {
                path: "callout_styles/social/youtube.png",
                background_color: "#FF0000"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#7B1212"
            },

            snap: {
              label: "SNAP",
              icon: {
                path: "callout_styles/social/snap.png",
                background_color: "#FEFC05"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#51511A"
            },

            mastodon: {
              label: "MASTODON",
              icon: {
                path: "callout_styles/social/mastodon.png",
                background_color: "#3188D4"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#1F4566"
            },

            blog: {
              label: "BLOG",
              icon: {
                path: "callout_styles/social/blog.png",
                background_color: "#5831D4"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#321E6F"
            },

            twitch: {
              label: "TWITCH",
              icon: {
                path: "callout_styles/social/twitch.png",
                background_color: "#9146FF"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#461B85"
            },

            github: {
              label: "GITHUB",
              icon: {
                path: "callout_styles/social/github.png",
                background_color: "#161514"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#373737"
            },

            soundcloud: {
              label: "SOUNDCLOUD",
              icon: {
                path: "callout_styles/social/soundcloud.png",
                background_color: "#FE2401"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#6D1507"
            },

            discord: {
              label: "DISCORD",
              icon: {
                path: "callout_styles/social/discord.png",
                background_color: "#5865F2"
              },
              label_style: LABEL_STYLE,
              text_style: TEXT_STYLE,
              background_color: "#2E389D"
            }
          }
        end

        def self.schema_path
          ScreenKit.root_dir.join("schemas/callout_styles/social.json")
        end

        def initialize(source:, text:, preset: nil, **kwargs)
          @text = text
          self.class.validate!(kwargs)
          super
          self.options = self.class.presets.fetch(preset.to_sym) if preset

          options.each do |key, value|
            value = case key
                    when :label_style, :text_style
                      TextStyle.new(source:, **hi_res(**value))
                    else
                      value
                    end

            instance_variable_set(:"@#{key}", value)
          end
        end

        def as_json(*)
          {}
        end

        def render
          label_path, label_width, label_height = render_text_image(
            type: "label",
            text: label,
            style: label_style,
            width: 600
          )

          text_path, text_width, _ = render_text_image(
            type: "label",
            text:,
            style: text_style,
            width: 600
          )

          sizes = hi_res(
            icon: 132,
            padding: 20,
            content_width: [label_width, text_width].max,
            image_height: 172,
            icon_radius: 30,
            panel_radius: 40
          )

          image_width = (sizes[:icon] + (sizes[:padding] * 2)) +
                        sizes[:padding] +
                        (sizes[:content_width] / 2) +
                        (sizes[:padding] * 2)
          image_height = sizes[:image_height]
          offset_x = sizes[:icon] + sizes[:padding]
          offset_y = sizes[:padding]
          icon_y = offset_y + sizes[:icon]

          MiniMagick.convert do |image|
            # Create transparent canvas
            image << "-size"
            image << "#{image_width}x#{image_height}"
            image << "xc:none"

            # Draw main background
            image << "-fill"
            image << options[:background_color]
            image << "-draw"
            image << "roundrectangle 0,0,#{image_width},#{image_height}," \
                     "#{sizes[:panel_radius]},#{sizes[:panel_radius]}"

            # Draw icon background
            image << "-fill"
            image << icon[:background_color]
            image << "-draw"
            image << "roundrectangle #{sizes[:padding]},#{sizes[:padding]}," \
                     "#{offset_x},#{icon_y}," \
                     "#{sizes[:icon_radius]},#{sizes[:icon_radius]}"

            # Draw icon
            icon_path = source.search(icon[:path])
            icon_image = MiniMagick::Image.open(icon_path)
            icon_x = sizes[:padding] + ((sizes[:icon] - icon_image.width) / 2)
            icon_y = offset_y + ((sizes[:icon] - icon_image.height) / 2)

            image << icon_path
            image << "-geometry"
            image << "+#{icon_x}+#{icon_y}"
            image << "-composite"

            offset_x += sizes[:padding]
            offset_y += sizes[:padding] / 2

            # Composite label
            image << label_path
            image << "-geometry"
            image << "+#{offset_x}+#{offset_y}"
            image << "-composite"

            offset_y += label_height

            # Composite text
            image << text_path
            image << "-geometry"
            image << "+#{offset_x}+#{offset_y}"
            image << "-composite"

            image << "PNG:#{output_path}"
          end

          output_path
        rescue MiniMagick::Error => error
          retry if error.message.include?("No such file or directory")
          raise
        ensure
          remove_file(label_path)
          remove_file(text_path)
        end
      end
    end
  end
end

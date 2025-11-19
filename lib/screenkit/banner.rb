# frozen_string_literal: true

module ScreenKit
  class Banner
    def self.source
      version = "v#{VERSION}"
      version_line = "┃#{' ' * (69 - version.size)}#{version}     ┃ ║"

      <<~TEXT
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃  Terminal to screencast, simplified                                      ┃═╗
        ┃  ███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗██╗  ██╗██╗████████╗  ┃ ║
        ┃  ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║██║ ██╔╝██║╚══██╔══╝  ┃ ║
        ┃  ███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║█████╔╝ ██║   ██║     ┃ ║
        ┃  ╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║██╔═██╗ ██║   ██║     ┃ ║
        ┃  ███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║██║  ██╗██║   ██║     ┃ ║
        ┃  ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝   ╚═╝     ┃ ║
        #{version_line}
        ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║
          ╚══════════════════════════════════════════════════════════════════════════╝
      TEXT
    end

    def self.banner
      return source if !$stdout.tty? || ENV["NO_COLOR"]

      colors = ["\e[31m", "\e[32m", "\e[33m", "\e[34m", "\e[35m", "\e[36m"]
      text = colors.sample
      accent = (colors - [text]).sample
      clear = "\e[0m"

      chars = source.each_char.with_object([]) do |char, buffer|
        buffer << case char
                  when /[A-Za-z0-9.,]/
                    "#{text}#{char}#{clear}"
                  when "╚", "═", "║", "╝", "╔", "╗"
                    "\e[37m#{char}#{clear}"
                  else
                    "#{accent}#{char}#{clear}"
                  end
      end

      chars.join
    end
  end
end

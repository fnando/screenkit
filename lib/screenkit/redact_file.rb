# frozen_string_literal: true

module ScreenKit
  module RedactFile
    # Redacts sensitive text from a file.
    # @param path [String] The file path.
    # @param text [String] The text to redact.
    # @return [void]
    def redact_file(path, text)
      return unless path
      return unless File.file?(path)

      content = File.read(path).gsub(text, "[REDACTED]")
      File.write(path, content)
    end
  end
end

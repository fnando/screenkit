# frozen_string_literal: true

module ScreenKit
  module HTTP
    def post(url:, params:, headers:, api_key:, log_path: nil)
      if log_path
        File.open(log_path, "w") do |f|
          f << JSON.pretty_generate(url:, params:, headers:)
        end
      end

      client = Aitch::Namespace.new
      client.configure do |config|
        config.logger = Logger.new(log_path) if log_path
      end

      client.post(
        url:,
        body: params,
        options: {expect: 200},
        headers: headers.merge(user_agent: "ScreenKit/#{ScreenKit::VERSION}")
      )
    ensure
      redact_file(log_path, api_key)
    end

    def json_post(headers:, **)
      headers = headers.merge(content_type: "application/json")
      post(headers:, **)
    end

    def redact_file(path, text)
      return unless path
      return unless File.file?(path)

      content = File.read(path).gsub(text, "[REDACTED]")
      File.write(path, content)
    end
  end
end

# frozen_string_literal: true

module ScreenKit
  module HTTP
    include RedactFile

    # Sends a POST request.
    #
    # @param url [String] The request URL.
    # @param params [Hash] The request parameters.
    # @param headers [Hash] The request headers.
    # @param api_key [String] The API key to redact from logs.
    # @param log_path [String, nil] The path to log the request details.
    # @return [Aitch::Response] The response.
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
        params:,
        options: {expect: 200},
        headers: headers.merge(user_agent: "ScreenKit/#{ScreenKit::VERSION}")
      )
    ensure
      redact_file(log_path, api_key)
    end

    # Sends a JSON POST request.
    #
    # @param url [String] The request URL.
    # @param params [Hash] The request parameters.
    # @param headers [Hash] The request headers.
    # @param api_key [String] The API key to redact from logs.
    # @param log_path [String, nil] The path to log the request details.
    # @return [Aitch::Response] The response.
    def json_post(headers:, **)
      headers = headers.merge(content_type: "application/json")
      post(headers:, **)
    end
  end
end

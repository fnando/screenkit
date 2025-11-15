# frozen_string_literal: true

module ScreenKit
  module SchemaValidator
    def validate!(attributes)
      errors = JSON::Validator
               .fully_validate("file://#{schema_path}", attributes)

      return if errors.empty?

      raise ArgumentError, "Invalid attributes: #{errors.first}"
    end
  end
end

# frozen_string_literal: true

module ScreenKit
  module Shell
    Error = Class.new(StandardError) do
      attr_reader :stdout, :stderr, :command, :args

      def initialize(message, stdout:, stderr:, command:, args:)
        super(message)
        @stdout = stdout
        @stderr = stderr
        @command = command
        @args = args
      end
    end

    def run_command(command, *args)
      args = args.flatten.compact.map(&:to_s)
      stdout, stderr, status = Open3.capture3(command, *args)
      exit_code = status.exitstatus

      if exit_code&.nonzero?
        $stderr << "#{stdout}\n" unless stdout.empty?
        $stderr << "#{stderr}\n" unless stderr.empty?

        raise Error.new(
          "#{command.inspect} failed with exit=#{exit_code}",
          stdout:,
          stderr:,
          command:,
          args:
        )
      end

      [stdout, stderr]
    end
  end
end

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

    # Checks if a command exists in the system's PATH.
    # Right now we're completely ignoring Windows (unless it's running on WSL).
    def command_exist?(command)
      !`which #{command}`.strip.empty?
    end

    def run_command(command, *args, log_path: nil)
      args = args.flatten.compact.map(&:to_s)
      stdout, stderr, status = Open3.capture3(command, *args)
      exit_code = status.exitstatus

      if exit_code&.nonzero?
        output = [command, *args].join(" ")
        $stderr << "Command failed: #{output}\n"
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
    ensure
      if log_path
        header = ->(text) { ("=" * 10) + " #{text} " + ("=" * 10) }

        File.open(log_path, "w") do |f|
          f << "#{header.call('COMMAND')}\n\n"
          f << "#{[command, *args].join(' ')}\n\n"

          f << "#{header.call('EXIT CODE')}\n\n"
          f << "#{exit_code}\n\n"

          f << "#{header.call('STDOUT')}\n\n"
          f << "#{stdout}\n\n"

          f << "#{header.call('STDERR')}\n\n"
          f << "#{stderr}\n"
        end
      end
    end
  end
end

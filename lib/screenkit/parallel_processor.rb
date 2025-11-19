# frozen_string_literal: true

module ScreenKit
  class ParallelProcessor
    attr_reader :spinner, :list, :message, :mutex, :count, :log_path
    attr_accessor :progress

    def initialize(spinner:, list:, message:, log_path: nil)
      @list = list
      @message = message
      @spinner = spinner
      @mutex = Mutex.new
      @progress = 0
      @count = list.size
      @log_path = log_path
    end

    def run(&block)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      indexed_list = list.map.with_index {|item, index| [item, index] }
      arity = block.arity

      indexed_list.each_slice(Etc.nprocessors) do |slice|
        threads = slice.map do |args|
          thread = Thread.new do
            yield(*args.take([1, arity].max), log_path:)
            update_progress
          end

          thread.abort_on_exception = true
          thread
        end

        threads.each(&:join)
      end

      spinner.stop

      ended_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ended_at - started_at
    end

    def update_progress
      mutex.synchronize do
        self.progress += 1
        spinner.update(format(message, count:, progress:))
      end
    end
  end
end

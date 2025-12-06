# frozen_string_literal: true

module ScreenKit
  class Logfile
    attr_reader :root_dir, :basename, :mutex
    attr_accessor :index

    def initialize(root_dir)
      @root_dir = root_dir
      @index = 0
      @mutex = Mutex.new
    end

    def create(*args)
      args.unshift(mutex.synchronize { format("%04d", index) })
      mutex.synchronize { self.index += 1 }

      Pathname(root_dir).join("#{args.join('-')}.txt")
    end

    def log(*args)
      message = args.pop
      path = create(*args)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") { it << message.to_s }
      path
    end

    def json_log(*args)
      message = args.pop
      log(*args, JSON.pretty_generate(message))
    end
  end
end

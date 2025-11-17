# frozen_string_literal: true

module ScreenKit
  class PathLookup
    # The directories to search for files.
    attr_reader :dirs

    def initialize(*dirs)
      @dirs = dirs.map { Pathname(it) }
    end

    # Search for the given path in the configured directories.
    # @param path [String, Pathname] The relative path to search for.
    # @return [Pathname, nil] The found path or nil if not found.
    def search(path, default: nil)
      dirs.each do |dir|
        candidate = dir.join(path)
        return candidate if candidate.exist?
      end

      return default if default

      raise FileEntryNotFoundError,
            %[No file entry found for #{path.to_s.inspect}]
    end
  end
end

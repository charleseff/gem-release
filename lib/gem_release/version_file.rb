require 'core_ext/kernel/silence'

module GemRelease
  class VersionFile
    include GemRelease::Helpers

    VERSION_PATTERN = /(VERSION\s*=\s*(?:"|'))(\d+\.\d+\.\d+)("|')/
    NUMBER_PATTERN  = /(\d+)\.(\d+)\.(\d+)/

    attr_reader :target

    def initialize(options = {})
      @target = options[:target] || :patch
    end

    def bump!
      File.open(filename, 'w+') { |f| f.write(bumped_content) }
      require_version
    end

    def new_number
      @new_number ||= old_number.sub(NUMBER_PATTERN) do
        respond_to?(target) ? send(target, $1, $2, $3) : target
      end
    end

    def old_number
      @old_number ||= content =~ VERSION_PATTERN && $2
    end

    def filename
      path = gem_name
      path = path.gsub('-', '/') unless File.exists?(path_to_version_file(path))
      path = path.gsub('/', '_') unless File.exists?(path_to_version_file(path))

      File.expand_path(path_to_version_file(path))
    end

    protected

      def path_to_version_file(path)
        "lib/#{path}/version.rb"
      end

      def require_version
        silence { require(filename) }
      end

      def major(major, minor, patch)
        "#{major.to_i + 1}.0.0"
      end

      def minor(major, minor, patch)
        "#{major}.#{minor.to_i + 1}.0"
      end

      def patch(major, minor, patch)
        "#{major}.#{minor}.#{patch.to_i + 1}"
      end

      def content
        @content ||= File.read(filename)
      end

      def bumped_content
        content.sub(VERSION_PATTERN) { "#{$1}#{new_number}#{$3}" }
      end
  end
end

# frozen_string_literal: true

require "fileutils"

module GitJump
  module Utils
    # XDG Base Directory Specification support
    # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    module XDG
      class << self
        def config_home
          ENV.fetch("XDG_CONFIG_HOME", File.join(Dir.home, ".config"))
        end

        def data_home
          ENV.fetch("XDG_DATA_HOME", File.join(Dir.home, ".local", "share"))
        end

        def cache_home
          ENV.fetch("XDG_CACHE_HOME", File.join(Dir.home, ".cache"))
        end

        def config_path(custom_path = nil)
          return custom_path if custom_path

          File.join(config_home, "git-jump", "config.toml")
        end

        def database_path
          File.join(data_home, "git-jump", "branches.db")
        end

        def ensure_directories!
          [config_dir, data_dir, cache_dir].each do |dir|
            FileUtils.mkdir_p(dir) unless File.directory?(dir)
          end
        end

        private

        def config_dir
          File.join(config_home, "git-jump")
        end

        def data_dir
          File.join(data_home, "git-jump")
        end

        def cache_dir
          File.join(cache_home, "git-jump")
        end
      end
    end
  end
end

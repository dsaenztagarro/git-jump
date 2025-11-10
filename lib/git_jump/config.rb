# frozen_string_literal: true

require "toml-rb"

module GitJump
  # Manages configuration from TOML file
  class Config
    attr_reader :path, :data

    DEFAULT_CONFIG = {
      "database" => {
        "path" => "$XDG_DATA_HOME/git-jump/branches.db"
      },
      "tracking" => {
        "max_branches" => 20,
        "auto_track" => true,
        "keep_patterns" => ["^main$", "^master$", "^develop$", "^staging$"]
      },
      "projects" => []
    }.freeze

    def initialize(path = nil)
      @path = Utils::XDG.config_path(path)
      @data = load_config
    end

    def self.default_config_content
      <<~TOML
        [database]
        # SQLite database location (defaults to XDG_DATA_HOME/git-jump/branches.db)
        # You can use environment variables like $XDG_DATA_HOME or $HOME
        path = "$XDG_DATA_HOME/git-jump/branches.db"

        [tracking]
        # Maximum number of branches to track per project
        max_branches = 20

        # Automatically track branches on checkout (via git hook)
        auto_track = true

        # Global branch patterns to always keep when clearing (regex patterns)
        keep_patterns = ["^main$", "^master$", "^develop$", "^staging$"]

        # Example project-specific configuration
        # [[projects]]
        # name = "my-project"
        # path = "/path/to/my-project"
        # keep_patterns = ["^main$", "^feature/.*$"]
      TOML
    end

    def exists?
      File.exist?(@path)
    end

    def database_path
      expand_env_vars(data.dig("database", "path") || Utils::XDG.database_path)
    end

    def max_branches
      data.dig("tracking", "max_branches") || 20
    end

    def auto_track?
      data.dig("tracking", "auto_track") != false
    end

    def keep_patterns(project_path = nil)
      # Check for project-specific patterns first
      if project_path
        project = find_project(project_path)
        return project["keep_patterns"] if project && project["keep_patterns"]
      end

      # Fall back to global patterns
      data.dig("tracking", "keep_patterns") || []
    end

    def find_project(project_path)
      projects = data["projects"] || []
      projects.find { |p| p["path"] == project_path }
    end

    private

    def load_config
      return DEFAULT_CONFIG unless File.exist?(@path)

      TomlRB.load_file(@path)
    rescue StandardError => e
      warn "Error loading config file: #{e.message}"
      warn "Using default configuration"
      DEFAULT_CONFIG
    end

    def expand_env_vars(path)
      return path unless path.is_a?(String)

      path.gsub(/\$(\w+)/) do |match|
        var_name = match[1..]
        ENV.fetch(var_name, match)
      end
    end
  end
end

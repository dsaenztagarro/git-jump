# frozen_string_literal: true

# Lazy-load Thor only when CLI is used
require "thor" unless defined?(Thor)

module GitJump
  # Command-line interface using Thor
  class CLI < Thor
    class_option :config, type: :string, aliases: "-c", desc: "Path to config file"
    class_option :quiet, type: :boolean, aliases: "-q", desc: "Suppress output"
    class_option :verbose, type: :boolean, aliases: "-v", desc: "Verbose output"

    def self.exit_on_failure?
      true
    end

    desc "setup", "Initialize configuration file"
    long_desc <<-DESC
      Creates a default configuration file at ~/.config/git-jump/config.toml.

      The configuration file allows you to customize:
      - Database location
      - Maximum branches to track per project
      - Auto-tracking behavior
      - Branch patterns to keep when clearing

      You can edit the file after creation to match your preferences.
    DESC
    def setup
      require_relative "loaders/setup_loader"
      output = create_output
      action = GitJump::Actions::Setup.new(
        config_path: options[:config],
        output: output
      )
      exit(1) unless action.execute
    end

    desc "install", "Install post-checkout git hook in current repository"
    long_desc <<-DESC
      Installs a post-checkout git hook that automatically tracks branches
      when you check them out.

      The hook will:
      - Track branches automatically on checkout
      - Update last visited timestamp
      - Maintain branch order
      - Cleanup old branches if max limit exceeded

      Run this command in your git repository root.
    DESC
    def install
      require_relative "loaders/install_loader"
      action = create_action(GitJump::Actions::Install)
      exit(1) unless action.execute
    rescue GitJump::Repository::NotAGitRepositoryError => e
      create_output.error(e.message)
      exit(1)
    end

    desc "add BRANCH", "Manually add a branch to tracking"
    long_desc <<-DESC
      Adds a branch to the tracking database without checking it out.

      This is useful when you want to add branches to your quick-switch list
      without having to check them out first.

      The branch must exist in the repository (use --no-verify to skip this check).
    DESC
    option :verify, type: :boolean, default: true, desc: "Verify branch exists"
    def add(branch_name)
      require_relative "loaders/add_loader"
      action = create_action(GitJump::Actions::Add, branch_name: branch_name, verify: options[:verify])
      exit(1) unless action.execute
    rescue GitJump::Repository::NotAGitRepositoryError => e
      create_output.error(e.message)
      exit(1)
    end

    desc "list", "List tracked branches for current project"
    long_desc <<-DESC
      Displays all tracked branches for the current project in order,
      with their index numbers and last visited times.

      The current branch is highlighted. Use the index numbers with
      the 'jump' command to quickly switch to a specific branch.
    DESC
    def list
      require_relative "loaders/list_loader"
      action = create_action(GitJump::Actions::List)
      exit(1) unless action.execute
    rescue GitJump::Repository::NotAGitRepositoryError => e
      create_output.error(e.message)
      exit(1)
    end

    desc "jump [INDEX]", "Jump to next branch or specific index"
    long_desc <<-DESC
      Switches to the next branch in the tracking list, or to a specific
      branch by index number.

      Without an index, cycles through branches in order. When reaching
      the end, wraps back to the first branch.

      With an index (from 'git-jump list'), jumps directly to that branch.

      Examples:
        git-jump jump       # Jump to next branch
        git-jump jump 3     # Jump to branch at index 3
    DESC
    def jump(index = nil)
      require_relative "loaders/jump_loader"
      action = create_action(GitJump::Actions::Jump, index: index)
      exit(1) unless action.execute
    rescue GitJump::Repository::NotAGitRepositoryError => e
      create_output.error(e.message)
      exit(1)
    end

    desc "clear", "Clear branches not matching keep patterns"
    long_desc <<-DESC
      Removes branches from tracking that don't match the configured
      keep patterns.

      Keep patterns are configured in your config file and can be
      global or per-project. Common patterns:
        - ^main$       (exact match for 'main')
        - ^master$     (exact match for 'master')
        - ^feature/.*  (all branches starting with 'feature/')

      This helps keep your tracking list clean without losing important
      branches like main, develop, etc.

      You'll be prompted for confirmation before clearing.
    DESC
    def clear
      require_relative "loaders/clear_loader"
      action = create_action(GitJump::Actions::Clear)
      exit(1) unless action.execute
    rescue GitJump::Repository::NotAGitRepositoryError => e
      create_output.error(e.message)
      exit(1)
    end

    desc "status", "Show current status and configuration"
    long_desc <<-DESC
      Displays detailed information about:
      - Current project and branch
      - Configuration settings
      - Hook installation status
      - Tracking statistics

      Useful for debugging or verifying your setup.
    DESC
    def status
      require_relative "loaders/status_loader"
      action = create_action(GitJump::Actions::Status)
      exit(1) unless action.execute
    rescue GitJump::Repository::NotAGitRepositoryError => e
      create_output.error(e.message)
      exit(1)
    end

    desc "version", "Show version"
    def version
      require_relative "version" unless defined?(GitJump::VERSION)
      puts "git-jump #{GitJump::VERSION}"
    end

    private

    def create_output
      require_relative "utils/output" unless defined?(Utils::Output)
      Utils::Output.new(
        quiet: options[:quiet] || false,
        verbose: options[:verbose] || false
      )
    end

    def create_action(action_class, **extra_options)
      # Dependencies are already loaded by action-specific loaders
      output = create_output
      config = Config.new(options[:config])
      repository = Repository.new
      database = Database.new(config.database_path)

      action_class.new(
        config: config,
        database: database,
        repository: repository,
        output: output,
        **extra_options
      )
    end
  end
end

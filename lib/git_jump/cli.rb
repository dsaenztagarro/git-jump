# frozen_string_literal: true

require "optparse"

module GitJump
  # Command-line interface using OptionParser
  class CLI
    def self.start(argv)
      new.run(argv)
    end

    def run(argv)
      @global_options = { config: nil, quiet: false, verbose: false }

      return print_help_and_exit if argv.empty?

      command = argv.shift
      dispatch_command(command, argv)
    end

    private

    def print_help_and_exit
      print_help
      exit(0)
    end

    def dispatch_command(command, argv)
      case command
      when "setup"
        setup_command(argv)
      when "install"
        install_command(argv)
      when "add"
        add_command(argv)
      when "list"
        list_command(argv)
      when "jump"
        jump_command(argv)
      when "clear"
        clear_command(argv)
      when "status"
        status_command(argv)
      when "version", "-v", "--version"
        version_command
      when "help", "-h", "--help"
        print_help
      else
        handle_unknown_command(command)
      end
    end

    def handle_unknown_command(command)
      warn "Unknown command: #{command}"
      warn "Run 'git-jump help' for usage information."
      exit(1)
    end

    def setup_command(argv)
      parse_global_options(argv)
      require_relative "loaders/setup_loader"
      output = create_output
      action = GitJump::Actions::Setup.new(
        config_path: @global_options[:config],
        output: output
      )
      exit(1) unless action.execute
    end

    def install_command(argv)
      parse_global_options(argv)
      require_relative "loaders/install_loader"
      action = create_action(GitJump::Actions::Install)
      exit(1) unless action.execute
    rescue StandardError => e
      handle_repository_error(e)
    end

    def add_command(argv)
      options = { verify: true }

      parser = OptionParser.new do |opts|
        parse_global_option_definitions(opts)
        opts.on("--[no-]verify", "Verify branch exists (default: true)") do |v|
          options[:verify] = v
        end
      end

      parser.parse!(argv)
      parse_global_options_from_parsed(parser)

      if argv.empty?
        warn "Error: BRANCH argument is required"
        warn "Usage: git-jump add BRANCH [options]"
        exit(1)
      end

      branch_name = argv.shift

      require_relative "loaders/add_loader"
      action = create_action(GitJump::Actions::Add, branch_name: branch_name, verify: options[:verify])
      exit(1) unless action.execute
    rescue StandardError => e
      handle_repository_error(e)
    end

    def list_command(argv)
      parse_global_options(argv)
      require_relative "loaders/list_loader"
      action = create_action(GitJump::Actions::List)
      exit(1) unless action.execute
    rescue StandardError => e
      handle_repository_error(e)
    end

    def jump_command(argv)
      parse_global_options(argv)
      index = argv.shift

      require_relative "loaders/jump_loader"
      action = create_action(GitJump::Actions::Jump, index: index)
      exit(1) unless action.execute
    rescue StandardError => e
      handle_repository_error(e)
    end

    def clear_command(argv)
      parse_global_options(argv)
      require_relative "loaders/clear_loader"
      action = create_action(GitJump::Actions::Clear)
      exit(1) unless action.execute
    rescue StandardError => e
      handle_repository_error(e)
    end

    def status_command(argv)
      parse_global_options(argv)
      require_relative "loaders/status_loader"
      action = create_action(GitJump::Actions::Status)
      exit(1) unless action.execute
    rescue StandardError => e
      handle_repository_error(e)
    end

    def version_command
      require_relative "version" unless defined?(GitJump::VERSION)
      puts "git-jump #{GitJump::VERSION}"
    end

    def parse_global_options(argv)
      parser = OptionParser.new do |opts|
        parse_global_option_definitions(opts)
      end
      parser.parse!(argv)
      parse_global_options_from_parsed(parser)
    end

    def parse_global_option_definitions(opts)
      opts.on("-c", "--config PATH", "Path to config file") do |c|
        @global_options[:config] = c
      end
      opts.on("-q", "--quiet", "Suppress output") do
        @global_options[:quiet] = true
      end
      opts.on("-v", "--verbose", "Verbose output") do
        @global_options[:verbose] = true
      end
    end

    def parse_global_options_from_parsed(_parser)
      # Already set in parse_global_option_definitions callbacks
    end

    def print_help
      puts <<~HELP
        Usage: git-jump COMMAND [options]

        Smart git branch tracker and switcher with SQLite persistence

        Commands:
          setup              Initialize configuration file
          install            Install post-checkout git hook in current repository
          add BRANCH         Manually add a branch to tracking
          list               List tracked branches for current project
          jump [INDEX]       Jump to next branch or specific index
          clear              Clear branches not matching keep patterns
          status             Show current status and configuration
          version            Show version
          help               Show this help message

        Global Options:
          -c, --config PATH  Path to config file
          -q, --quiet        Suppress output
          -v, --verbose      Verbose output

        Examples:
          git-jump setup                 # Initialize configuration
          git-jump install               # Install git hook
          git-jump add feature/new       # Add branch to tracking
          git-jump list                  # Show tracked branches
          git-jump jump                  # Jump to next branch
          git-jump jump 3                # Jump to branch at index 3
          git-jump clear                 # Clear old branches

        For more information, visit: https://github.com/dsaenztagarro/git-jump
      HELP
    end

    def create_output
      require_relative "utils/output" unless defined?(Utils::Output)
      Utils::Output.new(
        quiet: @global_options[:quiet],
        verbose: @global_options[:verbose]
      )
    end

    def create_action(action_class, **extra_options)
      # Dependencies are already loaded by action-specific loaders
      output = create_output
      config = Config.new(@global_options[:config])
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

    def handle_repository_error(error)
      # Check if it's a NotAGitRepositoryError without requiring it to be loaded
      raise error unless error.class.name.end_with?("NotAGitRepositoryError")

      create_output.error(error.message)
      exit(1)
    end
  end
end

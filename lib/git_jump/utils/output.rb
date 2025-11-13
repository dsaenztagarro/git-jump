# frozen_string_literal: true

module GitJump
  module Utils
    # Handles formatted console output with colors and tables
    class Output
      attr_reader :quiet, :verbose

      def initialize(quiet: false, verbose: false)
        @quiet = quiet
        @verbose = verbose
      end

      def pastel
        @pastel ||= begin
          require "pastel" unless defined?(Pastel)
          Pastel.new
        end
      end

      def success(message)
        puts pastel.green("✓ #{message}") unless quiet
      end

      def error(message)
        warn pastel.red("✗ #{message}")
      end

      def warning(message)
        puts pastel.yellow("⚠ #{message}") unless quiet
      end

      def info(message)
        puts pastel.blue("ℹ #{message}") unless quiet
      end

      def debug(message)
        puts pastel.dim(message) if verbose
      end

      def heading(message)
        puts unless quiet
        puts pastel.bold.cyan(message) unless quiet
        puts pastel.dim("─" * message.length) unless quiet
      end

      def table(headers, rows)
        return if quiet

        require "tty-table" unless defined?(TTY::Table)
        tty_table = TTY::Table.new(headers, rows)
        puts tty_table.render(:unicode, padding: [0, 1])
      end

      def branch_list(branches, current_branch)
        return if quiet || branches.empty?

        heading("Tracked Branches")

        rows = branches.map.with_index(1) do |branch, index|
          name = branch["name"]
          marker = name == current_branch ? pastel.green("→") : " "
          styled_name = name == current_branch ? pastel.bold.green(name) : name
          last_visited = format_time(branch["last_visited_at"])

          ["#{marker} #{index}", styled_name, last_visited]
        end

        table(["#", "Branch", "Last Visited"], rows)
      end

      def prompt(message, default: "N")
        return true if quiet # Auto-confirm in quiet mode

        print pastel.yellow("#{message} [y/N] ")
        answer = $stdin.gets&.chomp&.downcase
        %w[y yes].include?(answer)
      end

      private

      def format_time(time_string)
        time = Time.parse(time_string)
        diff = Time.now - time

        case diff
        when 0..59
          "just now"
        when 60..3599
          "#{(diff / 60).to_i}m ago"
        when 3600..86_399
          "#{(diff / 3600).to_i}h ago"
        when 86_400..2_591_999
          "#{(diff / 86_400).to_i}d ago"
        else
          time.strftime("%Y-%m-%d")
        end
      rescue StandardError
        "unknown"
      end
    end
  end
end

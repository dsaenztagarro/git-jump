# frozen_string_literal: true

require_relative "../colors"

module GitJump
  module Utils
    # Handles formatted console output with colors and tables
    class Output
      attr_reader :quiet, :verbose

      def initialize(quiet: false, verbose: false)
        @quiet = quiet
        @verbose = verbose
      end

      def success(message)
        puts Colors.green("✓ #{message}") unless quiet
      end

      def error(message)
        warn Colors.red("✗ #{message}")
      end

      def warning(message)
        puts Colors.yellow("⚠ #{message}") unless quiet
      end

      def info(message)
        puts Colors.blue("ℹ #{message}") unless quiet
      end

      def debug(message)
        puts Colors.dim(message) if verbose
      end

      def heading(message)
        puts unless quiet
        puts Colors.cyan(message, bold: true) unless quiet
        puts Colors.dim("─" * message.length) unless quiet
      end

      def table(headers, rows)
        return if quiet

        require "terminal-table" unless defined?(Terminal::Table)
        table = Terminal::Table.new(headings: headers, rows: rows)
        puts table
      end

      def branch_list(branches, current_branch)
        return if quiet || branches.empty?

        rows = branches.map.with_index(1) do |branch, index|
          name = branch["name"]
          marker = name == current_branch ? Colors.green("→") : " "
          styled_name = name == current_branch ? Colors.green(name, bold: true) : name
          last_visited = format_time(branch["last_visited_at"])

          ["#{marker} #{index}", styled_name, last_visited]
        end

        table(["#", "Branch", "Last Visited"], rows)
      end

      def prompt(message, _default: "N")
        return true if quiet # Auto-confirm in quiet mode

        print Colors.yellow("#{message} [y/N] ")
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

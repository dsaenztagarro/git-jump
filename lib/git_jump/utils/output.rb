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

        max_branch_width = calculate_max_branch_width

        rows = branches.map.with_index(1) do |branch, index|
          name = branch["name"]
          marker = name == current_branch ? Colors.green("→") : " "
          styled_name = name == current_branch ? Colors.green(name, bold: true) : name
          truncated_name = truncate_text(styled_name, max_branch_width)
          last_visited = format_time(branch["last_visited_at"])

          ["#{marker} #{index}", truncated_name, last_visited]
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

      # Get terminal width using multiple detection methods
      def terminal_width
        # Try tput command
        width = `tput cols 2>/dev/null`.to_i
        return width if width.positive?

        # Try COLUMNS environment variable
        width = ENV.fetch("COLUMNS", 0).to_i
        return width if width.positive?

        # Default fallback
        80
      end

      # Calculate maximum width for branch names in the table
      # Table structure: | # | Branch | Last Visited |
      # Fixed widths:
      #   - '# ' column: ~5 chars (marker + index)
      #   - 'Last Visited' column: ~14 chars
      #   - Table borders and padding: ~12 chars
      def calculate_max_branch_width
        fixed_width = 5 + 14 + 12
        branch_width = terminal_width - fixed_width

        # Ensure minimum branch width for readability
        [branch_width, 20].max
      end

      # Strip ANSI color codes from text for accurate length calculation
      def strip_ansi_codes(text)
        text.gsub(/\e\[[0-9;]*m/, "")
      end

      # Truncate text to max_width, preserving ANSI color codes
      def truncate_text(text, max_width)
        plain_text = strip_ansi_codes(text)
        return text if plain_text.length <= max_width
        return "..." if max_width < 3

        # Check if text contains ANSI color codes
        if text.include?("\e[")
          # Extract all leading ANSI codes (color, bold, etc.)
          color_start = text[/^(\e\[[0-9;]*m)+/, 0] || ""
          color_end = text[/\e\[0m$/] || ""

          # Truncate the plain text and reapply colors
          truncated = "#{plain_text[0...(max_width - 3)]}..."
          color_start + truncated + color_end
        else
          # No color codes, simple truncation
          "#{plain_text[0...(max_width - 3)]}..."
        end
      end
    end
  end
end

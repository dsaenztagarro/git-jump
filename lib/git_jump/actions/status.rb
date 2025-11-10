# frozen_string_literal: true

require_relative "base"

module GitJump
  module Actions
    # Action to display current status and configuration
    class Status < Base
      def execute
        output.heading("Git Jump Status")

        output.info("Project: #{repository.project_basename}")
        output.info("Path: #{repository.project_path}")
        output.info("Current branch: #{repository.current_branch || "(none)"}")

        output.heading("Configuration")
        output.info("Config file: #{config.path}")
        output.info("Config exists: #{config.exists? ? "Yes" : "No"}")
        output.info("Database: #{config.database_path}")
        output.info("Max branches: #{config.max_branches}")
        output.info("Auto-track: #{config.auto_track? ? "Enabled" : "Disabled"}")
        output.info("Keep patterns: #{config.keep_patterns.join(", ")}")

        output.heading("Hook Status")
        hook_installed = repository.hook_installed?("post-checkout")
        output.info("Post-checkout hook: #{hook_installed ? "Installed" : "Not installed"}")

        output.heading("Tracking Statistics")
        stats = database.project_stats(project_id)
        output.info("Total branches tracked: #{stats[:total_branches]}")

        output.info("Most recent: #{stats[:most_recent]["name"]}") if stats[:most_recent]

        true
      end
    end
  end
end

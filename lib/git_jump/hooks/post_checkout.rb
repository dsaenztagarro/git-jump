# frozen_string_literal: true

require_relative "../repository"
require_relative "../config"
require_relative "../database"

module GitJump
  module Hooks
    # Post-checkout hook implementation
    class PostCheckout
      attr_reader :repository_path

      def initialize(repository_path)
        @repository_path = repository_path
      end

      def run
        repository = Repository.new(repository_path)
        config = Config.new

        return unless config.auto_track?

        database = Database.new(config.database_path)
        project = database.find_or_create_project(
          repository.project_path,
          repository.project_basename
        )

        current_branch = repository.current_branch
        return unless current_branch && !current_branch.empty?

        database.add_branch(project["id"], current_branch)

        # Cleanup old branches if exceeded max
        total = database.count_branches(project["id"])
        database.cleanup_old_branches(project["id"], config.max_branches) if total > config.max_branches

        database.close
      rescue StandardError
        # Silent fail in hooks to avoid interrupting git operations
        nil
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base"

module GitJump
  module Actions
    # Action to manually add a branch to tracking
    class Add < Base
      attr_reader :branch_name, :verify

      def initialize(branch_name:, verify: true, **)
        super(**)
        @branch_name = branch_name
        @verify = verify
      end

      def execute
        if verify && !repository.branch_exists?(branch_name)
          output.error("Branch '#{branch_name}' does not exist in repository")
          return false
        end

        database.add_branch(project_id, branch_name)
        output.success("Added branch '#{branch_name}' to tracking for #{repository.project_basename}")

        # Check if we've exceeded max_branches
        total = database.count_branches(project_id)
        max = config.max_branches

        output.warning("Project has #{total} branches (max: #{max}). Consider running 'git-jump clear'") if total > max

        true
      end
    end
  end
end

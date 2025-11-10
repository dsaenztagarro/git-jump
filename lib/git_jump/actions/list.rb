# frozen_string_literal: true

require_relative "base"

module GitJump
  module Actions
    # Action to list tracked branches
    class List < Base
      def execute
        branches = database.list_branches(project_id)

        if branches.empty?
          output.info("No branches tracked for #{repository.project_basename}")
          output.info("Use 'git-jump add <branch>' to add branches or 'git-jump install' to setup automatic tracking")
          return true
        end

        current_branch = repository.current_branch
        output.branch_list(branches, current_branch)

        true
      end
    end
  end
end

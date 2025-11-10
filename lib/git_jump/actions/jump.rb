# frozen_string_literal: true

require_relative "base"

module GitJump
  module Actions
    # Action to jump to next branch or specific index
    class Jump < Base
      attr_reader :index

      def initialize(index: nil, **options)
        super(**options)
        @index = index
      end

      def execute
        branches = database.list_branches(project_id)

        if branches.empty?
          output.error("No branches tracked for #{repository.project_basename}")
          output.info("Use 'git-jump add <branch>' to add branches")
          return false
        end

        target_branch = if index
                          database.branch_at_index(project_id, index.to_i)
                        else
                          current_branch = repository.current_branch
                          database.next_branch(project_id, current_branch)
                        end

        unless target_branch
          output.error("Invalid branch index: #{index}") if index
          return false
        end

        if target_branch == repository.current_branch
          output.info("Already on branch '#{target_branch}'")
          return true
        end

        repository.checkout(target_branch)
        database.add_branch(project_id, target_branch) # Update last_visited_at

        output.success("Switched to branch '#{target_branch}'")
        true
      rescue StandardError => e
        output.error(e.message)
        false
      end
    end
  end
end

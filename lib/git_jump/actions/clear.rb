# frozen_string_literal: true

require_relative "base"

module GitJump
  module Actions
    # Action to clear branches matching keep patterns
    class Clear < Base
      def execute
        branches = database.list_branches(project_id)

        if branches.empty?
          output.info("No branches tracked for #{repository.project_basename}")
          return true
        end

        keep_patterns = config.keep_patterns(repository.project_path)

        if keep_patterns.empty?
          output.warning("No keep patterns configured. All branches would be deleted.")
          output.info("Configure keep_patterns in your config file to use this command")
          return false
        end

        output.info("Keep patterns: #{keep_patterns.join(", ")}")

        unless output.prompt("Clear branches not matching patterns?")
          output.info("Cancelled")
          return false
        end

        deleted = database.clear_branches(project_id, keep_patterns)

        if deleted.zero?
          output.info("No branches to clear (all match keep patterns)")
        else
          output.success("Cleared #{deleted} branch(es)")
        end

        true
      end
    end
  end
end

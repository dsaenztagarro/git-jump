# frozen_string_literal: true

module GitJump
  class Action
    def initialize(repository_path)
      @repository_path = repository_path
      # @db = setup_database
    end

    def add(branch_name)
      project_name = File.basename(Dir.pwd)

      puts "GitJump::Action#add project_name: #{project_name}"

      # @db.execute(
      #   'INSERT INTO branches (project_name, branch_name) VALUES (?, ?)',
      #   [project_name, branch_name]
      # )

      puts "Branch '#{branch_name}' added for project '#{project_name}'"
    end

    def toggle
      project_name = File.basename(Dir.pwd)

      branches = @db.execute(
        "SELECT branch_name FROM branches WHERE project_name = ?",
        [project_name]
      ).map(&:first)

      if branches.empty?
        puts "No branches found for project '#{project_name}'"
        return
      end

      current_branch = `git branch --show-current`.strip
      next_branch = branches[(branches.index(current_branch) || -1) + 1] || branches.first

      system("git checkout #{next_branch}")
      puts "Switched to branch '#{next_branch}'"
    end
  end
end

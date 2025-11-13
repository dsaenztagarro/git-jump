# frozen_string_literal: true

require "fileutils"
require "shellwords"

module GitJump
  # Wrapper for git repository operations
  class Repository
    class NotAGitRepositoryError < StandardError; end

    attr_reader :path

    def initialize(path = Dir.pwd)
      @path = File.expand_path(path)
      raise NotAGitRepositoryError, "Not a git repository: #{@path}" unless valid?
    end

    def valid?
      git_dir = File.join(@path, ".git")
      File.directory?(git_dir) || find_git_root
    end

    def project_path
      @project_path ||= find_git_root || @path
    end

    def project_basename
      File.basename(project_path)
    end

    def current_branch
      result = execute_git("branch", "--show-current")
      result.strip
    rescue StandardError
      nil
    end

    def branches
      result = execute_git("branch", "--format=%(refname:short)")
      result.split("\n").map(&:strip)
    rescue StandardError
      []
    end

    def checkout(branch_name)
      # Set environment variable to skip git-jump hook during checkout
      # This prevents double-loading of gems when git-jump triggers checkout
      ENV["GIT_JUMP_SKIP_HOOK"] = "1"
      execute_git("checkout", branch_name)
      true
    rescue StandardError => e
      raise "Failed to checkout branch '#{branch_name}': #{e.message}"
    ensure
      ENV.delete("GIT_JUMP_SKIP_HOOK")
    end

    def branch_exists?(branch_name)
      branches.include?(branch_name)
    end

    def hook_path(hook_name)
      File.join(project_path, ".git", "hooks", hook_name)
    end

    def install_hook(hook_name, content)
      path = hook_path(hook_name)
      hooks_dir = File.dirname(path)

      # Create hooks directory if it doesn't exist
      FileUtils.mkdir_p(hooks_dir) unless File.directory?(hooks_dir)

      File.write(path, content)
      FileUtils.chmod(0o755, path)

      true
    rescue StandardError => e
      raise "Failed to install hook '#{hook_name}': #{e.message}"
    end

    def hook_installed?(hook_name)
      path = hook_path(hook_name)
      File.exist?(path) && File.executable?(path)
    end

    def read_hook(hook_name)
      File.read(hook_path(hook_name))
    rescue StandardError
      nil
    end

    private

    def find_git_root
      current = @path

      loop do
        return current if File.directory?(File.join(current, ".git"))

        parent = File.dirname(current)
        break if parent == current # reached root

        current = parent
      end

      nil
    end

    def execute_git(*args)
      Dir.chdir(project_path) do
        cmd = ["git"] + args
        output = `#{cmd.map { |arg| arg.shellescape }.join(" ")} 2>&1`
        raise "Git command failed: #{output}" unless $?.success?

        output
      end
    end
  end
end

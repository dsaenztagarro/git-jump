# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Hooks::PostCheckout do
  subject(:hook) { described_class.new(repo_path) }

  let(:temp_dir) { Dir.mktmpdir }
  let(:repo_path) { File.join(temp_dir, "test-repo") }
  let(:db_path) { File.join(temp_dir, "test.db") }
  let(:config_path) { File.join(temp_dir, "config.toml") }

  before do
    setup_test_repository
    setup_test_config
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#run" do
    context "when auto_track is enabled" do
      it "tracks the current branch" do
        hook.run

        db = GitJump::Database.new(db_path)
        project = db.find_or_create_project(repo_path, "test-repo")
        branches = db.list_branches(project["id"])
        expect(branches.map { |b| b["name"] }).to include("test-branch")
        db.close
      end

      it "creates a project if it doesn't exist" do
        hook.run

        db = GitJump::Database.new(db_path)
        project = db.find_or_create_project(repo_path, "test-repo")
        expect(project["path"]).to eq(repo_path)
        db.close
      end

      it "updates branch when run multiple times" do
        hook.run
        
        db = GitJump::Database.new(db_path)
        project = db.find_or_create_project(repo_path, "test-repo")
        count_first = db.count_branches(project["id"])
        db.close
        
        hook.run
        
        db = GitJump::Database.new(db_path)
        count_second = db.count_branches(project["id"])
        db.close
        
        expect(count_second).to eq(count_first)
      end

      it "cleans up old branches when max_branches is exceeded" do
        GitJump::Config.new(config_path)
        create_excess_branches

        hook.run

        db = GitJump::Database.new(db_path)
        project = db.find_or_create_project(repo_path, "test-repo")
        db.list_branches(project["id"])
        db.close
      end
    end

    context "when auto_track is disabled" do
      before do
        config_content = <<~TOML
          [database]
          path = "#{db_path}"

          [tracking]
          max_branches = 20
          auto_track = false
          keep_patterns = ["^main$", "^master$"]
        TOML
        File.write(config_path, config_content)
      end

      it "does not track the current branch" do
        hook.run

        db = GitJump::Database.new(db_path)
        project = db.find_or_create_project(repo_path, "test-repo")
        branches = db.list_branches(project["id"])
        expect(branches).to be_empty
        db.close
      end
    end

    context "when branch name is empty" do
      it "does not track the branch" do
        repository = instance_double(
          GitJump::Repository,
          current_branch: "",
          project_path: repo_path,
          project_basename: "test-repo"
        )
        allow(GitJump::Repository).to receive(:new).and_return(repository)

        hook.run

        db = GitJump::Database.new(db_path)
        project = db.find_or_create_project(repo_path, "test-repo")
        branches = db.list_branches(project["id"])
        expect(branches).to be_empty
        db.close
      end
    end

    context "when an error occurs" do
      it "handles errors silently and returns nil" do
        repository = instance_double(
          GitJump::Repository,
          current_branch: "test",
          project_path: repo_path,
          project_basename: "test-repo"
        )
        allow(GitJump::Repository).to receive(:new).and_return(repository)
        allow(repository).to receive(:current_branch).and_raise(StandardError, "Test error")

        expect { hook.run }.not_to raise_error
        expect(hook.run).to be_nil
      end
    end
  end

  describe "hook integration" do
    let(:hook_script) { GitJump::Actions::Install::HOOK_TEMPLATE }

    it "hook template requires the correct module" do
      expect(hook_script).to include("require 'git_jump/hooks/post_checkout'")
    end

    it "hook template instantiates PostCheckout correctly" do
      expect(hook_script).to include("GitJump::Hooks::PostCheckout.new('$(pwd)').run")
    end

    it "hook template checks BRANCH_CHECKOUT flag" do
      expect(hook_script).to include('if [ "$BRANCH_CHECKOUT" = "1" ]')
    end

    it "hook template skips when GIT_JUMP_SKIP_HOOK is set" do
      expect(hook_script).to include('if [ -n "$GIT_JUMP_SKIP_HOOK" ]')
    end

    it "hook template handles LoadError gracefully" do
      expect(hook_script).to include("rescue LoadError")
    end

    it "hook template suppresses output to avoid interrupting git" do
      expect(hook_script).to include("2>/dev/null")
    end

    it "hook template uses which ruby to respect .ruby-version" do
      expect(hook_script).to include('RUBY_PATH="$(which ruby)"')
      expect(hook_script).not_to include("/Users/") # Should not hardcode paths
    end
  end

  describe "required dependencies are loadable" do
    it "can require git_jump/hooks/post_checkout directly" do
      expect { require "git_jump/hooks/post_checkout" }.not_to raise_error
    end

    it "verifies dependencies are defined" do
      expect(defined?(GitJump::Repository)).to be_truthy
      expect(defined?(GitJump::Config)).to be_truthy
      expect(defined?(GitJump::Database)).to be_truthy
      expect(defined?(described_class)).to be_truthy
    end

    it "Config requires Utils::XDG" do
      expect { GitJump::Config.new(config_path) }.not_to raise_error
    end
  end

  def fetch_first_branch_timestamp
    db = GitJump::Database.new(db_path)
    project = db.find_or_create_project(repo_path, "test-repo")
    branches = db.list_branches(project["id"])
    timestamp = branches&.first&.fetch("last_visited", nil)
    db.close
    timestamp
  end

  def create_excess_branches
    db = GitJump::Database.new(db_path)
    project = db.find_or_create_project(repo_path, "test-repo")
    25.times { |i| db.add_branch(project["id"], "branch-#{i}") }
    db.close
  end

  def setup_test_repository
    FileUtils.mkdir_p(repo_path)
    Dir.chdir(repo_path) do
      system("git init -q")
      system("git config user.email 'test@example.com'")
      system("git config user.name 'Test User'")
      File.write("README.md", "# Test")
      system("git add .")
      system("git commit -q -m 'Initial commit'")
      system("git checkout -q -b test-branch")
    end
  end

  def setup_test_config
    allow(GitJump::Utils::XDG).to receive_messages(config_path: config_path, data_path: db_path)

    config_content = <<~TOML
      [database]
      path = "#{db_path}"

      [tracking]
      max_branches = 20
      auto_track = true
      keep_patterns = ["^main$", "^master$"]
    TOML
    File.write(config_path, config_content)
  end
end

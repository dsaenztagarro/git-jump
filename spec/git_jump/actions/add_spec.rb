# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::Add do
  subject(:action) do
    described_class.new(
      branch_name: "test-branch",
      config: config,
      repository: repository,
      database: database,
      output: output
    )
  end

  let(:temp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_dir, "config.toml") }
  let(:db_path) { File.join(temp_dir, "test.db") }
  let(:repo_path) { File.join(temp_dir, "repo") }

  let(:config) do
    instance_double(
      GitJump::Config,
      database_path: db_path,
      max_branches: 20,
      auto_track?: true,
      keep_patterns: ["^master$", "^main$"]
    )
  end

  let(:database) { GitJump::Database.new(db_path) }
  let(:repository) { instance_double(GitJump::Repository, project_basename: "test-repo", project_path: repo_path) }
  let(:output) { instance_double(GitJump::Utils::Output) }

  before do
    # Create a git repository
    Dir.mkdir(repo_path)
    Dir.chdir(repo_path) do
      `git init`
      `git config user.email "test@example.com"`
      `git config user.name "Test User"`
      `touch README.md`
      `git add .`
      `git commit -m "Initial commit"`
      `git checkout -b test-branch`
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#execute" do
    context "when branch exists in repository" do
      before do
        allow(repository).to receive(:branch_exists?).with("test-branch").and_return(true)
        allow(output).to receive(:success)
      end

      it "adds the branch to the database" do
        expect { action.execute }.to change { database.list_branches(action.send(:project_id)).count }.by(1)
      end

      it "outputs a success message" do
        expect(output).to receive(:success).with("Added branch 'test-branch' to tracking for test-repo")
        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end

    context "when branch does not exist in repository" do
      let(:nonexistent_action) do
        described_class.new(
          branch_name: "nonexistent",
          config: config,
          repository: repository,
          database: database,
          output: output
        )
      end

      before do
        allow(repository).to receive(:branch_exists?).with("nonexistent").and_return(false)
        allow(output).to receive(:error)
      end

      it "does not add the branch to the database" do
        expect { nonexistent_action.execute }.not_to(change do
          database.list_branches(nonexistent_action.send(:project_id)).count
        end)
      end

      it "outputs an error message" do
        expect(output).to receive(:error).with("Branch 'nonexistent' does not exist in repository")
        nonexistent_action.execute
      end

      it "returns false" do
        expect(nonexistent_action.execute).to be false
      end
    end

    context "when branch is already tracked" do
      before do
        allow(repository).to receive(:branch_exists?).with("test-branch").and_return(true)
        allow(output).to receive(:success)

        # Add the branch first time
        action.execute
      end

      it "updates the last visited timestamp" do
        expect { action.execute }.not_to(change { database.list_branches(action.send(:project_id)).count })
      end

      it "outputs a success message" do
        expect(output).to receive(:success).with("Added branch 'test-branch' to tracking for test-repo")
        action.execute
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::Jump do
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
  let(:repository) do
    instance_double(
      GitJump::Repository,
      project_basename: "test-repo",
      project_path: repo_path,
      current_branch: "master"
    )
  end
  let(:output) { instance_double(GitJump::Utils::Output) }

  subject(:action) do
    described_class.new(
      config: config,
      repository: repository,
      database: database,
      output: output
    )
  end

  let(:project_id) { database.find_or_create_project(repo_path, "test-repo")["id"] }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#execute" do
    context "when no branches are tracked" do
      before do
        allow(output).to receive(:error)
        allow(output).to receive(:info)
      end

      it "outputs an error message" do
        expect(output).to receive(:error).with("No branches tracked for test-repo")
        expect(output).to receive(:info).with("Use 'git-jump add <branch>' to add branches")
        action.execute
      end

      it "returns false" do
        expect(action.execute).to be false
      end
    end

    context "when jumping to next branch" do
      before do
        database.add_branch(project_id, "master")
        sleep 0.001 # Ensure unique timestamps
        database.add_branch(project_id, "feature/auth")
        sleep 0.001
        database.add_branch(project_id, "feature/api")

        allow(repository).to receive(:checkout)
        allow(output).to receive(:success)
      end

      it "checks out the next branch" do
        expect(repository).to receive(:checkout).with("feature/api")
        action.execute
      end

      it "updates the branch last visited timestamp" do
        allow(repository).to receive(:checkout).with("feature/api")

        # Before jump, feature/api is most recent
        expect(database.list_branches(project_id).first["name"]).to eq("feature/api")

        action.execute

        # After jump, feature/api is still most recent (its timestamp was updated)
        branches = database.list_branches(project_id)
        expect(branches.first["name"]).to eq("feature/api")
      end

      it "outputs a success message" do
        allow(repository).to receive(:checkout).with("feature/api")

        expect(output).to receive(:success).with("Switched to branch 'feature/api'")
        action.execute
      end

      it "returns true" do
        allow(repository).to receive(:checkout).with("feature/api")
        expect(action.execute).to be true
      end
    end

    context "when jumping to a specific index" do
      let(:indexed_repository) do
        instance_double(
          GitJump::Repository,
          project_basename: "test-repo",
          project_path: repo_path,
          current_branch: "feature/api"
        )
      end

      let(:indexed_action) do
        described_class.new(
          index: 3,
          config: config,
          repository: indexed_repository,
          database: database,
          output: output
        )
      end

      before do
        database.add_branch(project_id, "master")
        sleep 0.001 # Ensure unique timestamps
        database.add_branch(project_id, "feature/auth")
        sleep 0.001
        database.add_branch(project_id, "feature/api")

        allow(indexed_repository).to receive(:checkout)
        allow(output).to receive(:success)
      end

      it "checks out the branch at the specified index" do
        expect(indexed_repository).to receive(:checkout).with("master")
        indexed_action.execute
      end

      it "outputs a success message" do
        allow(indexed_repository).to receive(:checkout).with("master")

        expect(output).to receive(:success).with("Switched to branch 'master'")
        indexed_action.execute
      end

      it "returns true" do
        allow(indexed_repository).to receive(:checkout).with("master")
        expect(indexed_action.execute).to be true
      end
    end

    context "when index is out of range" do
      let(:invalid_action) do
        described_class.new(
          index: 5,
          config: config,
          repository: repository,
          database: database,
          output: output
        )
      end

      before do
        database.add_branch(project_id, "master")
        allow(output).to receive(:error)
      end

      it "outputs an error message" do
        expect(output).to receive(:error).with("Invalid branch index: 5")
        invalid_action.execute
      end

      it "returns false" do
        expect(invalid_action.execute).to be false
      end
    end

    context "when checkout fails" do
      before do
        database.add_branch(project_id, "master")
        sleep 0.001 # Ensure unique timestamps
        database.add_branch(project_id, "feature/auth")

        allow(repository).to receive(:checkout).and_raise("Failed to checkout")
        allow(output).to receive(:error)
      end

      it "outputs an error message" do
        expect(output).to receive(:error).with("Failed to checkout")
        action.execute
      end

      it "returns false" do
        expect(action.execute).to be false
      end
    end
  end
end

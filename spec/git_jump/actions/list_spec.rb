# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::List do
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

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#execute" do
    context "when no branches are tracked" do
      before do
        allow(output).to receive(:info)
      end

      it "outputs info messages" do
        expect(output).to receive(:info).with("No branches tracked for test-repo")
        expect(output).to receive(:info).with("Use 'git-jump add <branch>' to add branches or 'git-jump install' to setup automatic tracking")

        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end

    context "when branches are tracked" do
      let(:project_id) { database.find_or_create_project(repo_path, "test-repo")["id"] }

      before do
        database.add_branch(project_id, "feature/auth")
        database.add_branch(project_id, "feature/api")
        database.add_branch(project_id, "master")

        allow(output).to receive(:branch_list)
      end

      it "outputs the branch list" do
        branches = database.list_branches(project_id)

        expect(output).to receive(:branch_list).with(branches, "master")
        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end
  end
end

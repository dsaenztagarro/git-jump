# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::Clear do
  subject(:action) do
    described_class.new(
      config: config,
      repository: repository,
      database: database,
      output: output
    )
  end

  let(:temp_dir) { Dir.mktmpdir }
  let(:project_id) { database.find_or_create_project(repo_path, "test-repo")["id"] }
  let(:config_path) { File.join(temp_dir, "config.toml") }
  let(:db_path) { File.join(temp_dir, "test.db") }
  let(:repo_path) { File.join(temp_dir, "repo") }

  let(:config) do
    instance_double(
      GitJump::Config,
      database_path: db_path,
      max_branches: 20,
      auto_track?: true,
      keep_patterns: ["^master$", "^main$", "^develop$"]
    )
  end

  let(:database) { GitJump::Database.new(db_path) }
  let(:repository) do
    instance_double(
      GitJump::Repository,
      project_basename: "test-repo",
      project_path: repo_path
    )
  end
  let(:output) { instance_double(GitJump::Utils::Output) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#execute" do
    context "when no branches are tracked" do
      before do
        allow(output).to receive(:info)
      end

      it "outputs an info message" do
        expect(output).to receive(:info).with("No branches tracked for test-repo")
        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end

    context "when user confirms clearing" do
      before do
        database.add_branch(project_id, "master")
        database.add_branch(project_id, "feature/auth")
        database.add_branch(project_id, "feature/api")
        database.add_branch(project_id, "bugfix/login")

        allow(output).to receive(:info)
        allow(output).to receive(:prompt).and_return(true)
        allow(output).to receive(:success)
      end

      it "displays keep patterns" do
        expect(output).to receive(:info).with("Keep patterns: ^master$, ^main$, ^develop$")
        action.execute
      end

      it "prompts for confirmation" do
        expect(output).to receive(:prompt).with("Clear branches not matching patterns?")
        action.execute
      end

      it "clears branches not matching keep patterns" do
        expect { action.execute }.to change { database.list_branches(project_id).count }.from(4).to(1)
      end

      it "keeps branches matching keep patterns" do
        action.execute

        branches = database.list_branches(project_id)
        expect(branches.map { |b| b["name"] }).to eq(["master"])
      end

      it "outputs a success message" do
        expect(output).to receive(:success).with("Cleared 3 branch(es)")
        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end

    context "when user cancels clearing" do
      before do
        database.add_branch(project_id, "master")
        database.add_branch(project_id, "feature/auth")

        allow(output).to receive(:info)
        allow(output).to receive(:prompt).and_return(false)
      end

      it "does not clear any branches" do
        expect { action.execute }.not_to(change { database.list_branches(project_id).count })
      end

      it "outputs a cancellation message" do
        expect(output).to receive(:info).with("Cancelled")
        action.execute
      end

      it "returns false" do
        expect(action.execute).to be false
      end
    end
  end
end

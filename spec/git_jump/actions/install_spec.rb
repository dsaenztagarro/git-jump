# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::Install do
  subject(:action) do
    described_class.new(
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
    context "when hook is successfully installed" do
      before do
        allow(repository).to receive(:hook_installed?).with("post-checkout").and_return(false)
        allow(repository).to receive(:install_hook).and_return(true)
        allow(output).to receive(:success)
        allow(output).to receive(:info)
      end

      it "installs the post-checkout hook" do
        expect(repository).to receive(:install_hook).with("post-checkout", anything)
        action.execute
      end

      it "outputs success messages" do
        expect(output).to receive(:success).with("Installed post-checkout hook in test-repo")
        expect(output).to receive(:info).with("Branches will now be automatically tracked on checkout")

        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end

    context "when hook installation fails" do
      before do
        allow(repository).to receive(:hook_installed?).with("post-checkout").and_return(false)
        allow(repository).to receive(:install_hook).and_raise("Permission denied")
        allow(output).to receive(:error)
      end

      it "outputs an error message" do
        expect(output).to receive(:error).with("Failed to install hook: Permission denied")
        action.execute
      end

      it "returns false" do
        expect(action.execute).to be false
      end
    end
  end
end

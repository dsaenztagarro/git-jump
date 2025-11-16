# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::Status do
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
      path: config_path,
      database_path: db_path,
      max_branches: 20,
      auto_track?: true,
      keep_patterns: ["^master$", "^main$", "^develop$"],
      exists?: true
    )
  end

  let(:database) { GitJump::Database.new(db_path) }
  let(:repository) do
    instance_double(
      GitJump::Repository,
      project_basename: "test-repo",
      project_path: repo_path,
      current_branch: "master",
      hook_installed?: false
    )
  end
  let(:output) { instance_double(GitJump::Utils::Output) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#execute" do
    before do
      allow(output).to receive(:heading)
      allow(output).to receive(:info)
    end

    context "when displaying project information" do
      it "displays project details" do
        expect(output).to receive(:heading).with("Git Jump Status")
        expect(output).to receive(:info).with("Project: test-repo")
        expect(output).to receive(:info).with("Path: #{repo_path}")
        expect(output).to receive(:info).with("Current branch: master")

        action.execute
      end
    end

    context "when displaying configuration" do
      before do
        FileUtils.mkdir_p(File.dirname(config_path))
        File.write(config_path, "test config")
      end

      it "displays config details" do
        expect(output).to receive(:heading).with("Configuration")
        expect(output).to receive(:info).with("Config file: #{config_path}")
        expect(output).to receive(:info).with("Config exists: Yes")
        expect(output).to receive(:info).with("Database: #{db_path}")
        expect(output).to receive(:info).with("Max branches: 20")
        expect(output).to receive(:info).with("Auto-track: Enabled")
        expect(output).to receive(:info).with("Keep patterns: ^master$, ^main$, ^develop$")

        action.execute
      end
    end

    context "when config file does not exist" do
      let(:config_not_exists) do
        instance_double(
          GitJump::Config,
          path: config_path,
          database_path: db_path,
          max_branches: 20,
          auto_track?: true,
          keep_patterns: ["^master$", "^main$", "^develop$"],
          exists?: false
        )
      end

      let(:action_no_config) do
        described_class.new(
          config: config_not_exists,
          repository: repository,
          database: database,
          output: output
        )
      end

      it "displays config does not exist" do
        expect(output).to receive(:info).with("Config exists: No")
        action_no_config.execute
      end
    end

    context "when displaying hook status" do
      it "displays hook not installed" do
        expect(output).to receive(:heading).with("Hook Status")
        expect(output).to receive(:info).with("Post-checkout hook: Not installed")

        action.execute
      end

      context "when hook is installed" do
        before do
          allow(repository).to receive(:hook_installed?).and_return(true)
        end

        it "displays hook installed" do
          expect(output).to receive(:info).with("Post-checkout hook: Installed")
          action.execute
        end
      end
    end

    context "when displaying tracking statistics" do
      context "with no tracked branches" do
        it "displays zero branches tracked" do
          expect(output).to receive(:heading).with("Tracking Statistics")
          expect(output).to receive(:info).with("Total branches tracked: 0")

          action.execute
        end
      end

      context "with tracked branches" do
        before do
          database.add_branch(project_id, "master")
          sleep 0.001 # Ensure unique timestamps
          database.add_branch(project_id, "feature/auth")
          sleep 0.001
          database.add_branch(project_id, "feature/api")
        end

        it "displays branch count and most recent" do
          expect(output).to receive(:heading).with("Tracking Statistics")
          expect(output).to receive(:info).with("Total branches tracked: 3")
          expect(output).to receive(:info).with("Most recent: feature/api")

          action.execute
        end
      end
    end

    it "returns true" do
      expect(action.execute).to be true
    end
  end
end

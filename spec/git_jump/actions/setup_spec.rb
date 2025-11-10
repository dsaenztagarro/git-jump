# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Actions::Setup do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_dir, "config.toml") }
  let(:output) { instance_double(GitJump::Utils::Output) }

  subject(:action) do
    described_class.new(
      config_path: config_path,
      output: output
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#execute" do
    context "when config file does not exist" do
      before do
        allow(output).to receive(:success)
        allow(output).to receive(:info)
      end

      it "creates the default config file" do
        action.execute
        expect(File.exist?(config_path)).to be true
      end

      it "outputs success messages" do
        expect(output).to receive(:success).with("Created config file at: #{config_path}")
        expect(output).to receive(:info).with("Edit this file to customize your branch tracking settings")

        action.execute
      end

      it "returns true" do
        expect(action.execute).to be true
      end
    end

    context "when config file already exists" do
      before do
        FileUtils.mkdir_p(File.dirname(config_path))
        File.write(config_path, "existing config")

        allow(output).to receive(:warning)
        allow(output).to receive(:prompt).and_return(false)
      end

      it "does not overwrite the existing config" do
        action.execute
        expect(File.read(config_path)).to eq("existing config")
      end

      it "outputs a warning message" do
        expect(output).to receive(:warning).with("Config file already exists at: #{config_path}")
        action.execute
      end

      it "returns false when user does not confirm" do
        expect(action.execute).to be false
      end

      context "when user confirms overwrite" do
        before do
          allow(output).to receive(:prompt).and_return(true)
          allow(output).to receive(:success)
          allow(output).to receive(:info)
        end

        it "overwrites the config file" do
          action.execute
          expect(File.read(config_path)).not_to eq("existing config")
        end
      end
    end

    context "when config creation fails" do
      before do
        allow(File).to receive(:write).and_raise("Permission denied")
        allow(output).to receive(:error)
      end

      it "outputs an error message" do
        expect(output).to receive(:error).with("Failed to create config file: Permission denied")
        action.execute
      end

      it "returns false" do
        expect(action.execute).to be false
      end
    end
  end
end

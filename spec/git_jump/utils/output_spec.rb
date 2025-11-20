# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump::Utils::Output do
  subject(:output) { described_class.new(quiet: quiet, verbose: verbose) }

  let(:quiet) { false }
  let(:verbose) { false }

  describe "#strip_ansi_codes" do
    it "removes ANSI color codes from text" do
      colored_text = "\e[38;5;34mgreen text\e[0m"
      expect(output.send(:strip_ansi_codes, colored_text)).to eq("green text")
    end

    it "removes bold ANSI codes" do
      bold_text = "\e[1mbold text\e[0m"
      expect(output.send(:strip_ansi_codes, bold_text)).to eq("bold text")
    end

    it "removes multiple ANSI codes" do
      colored_bold_text = "\e[38;5;34m\e[1mgreen bold\e[0m"
      expect(output.send(:strip_ansi_codes, colored_bold_text)).to eq("green bold")
    end

    it "returns plain text unchanged" do
      plain_text = "plain text"
      expect(output.send(:strip_ansi_codes, plain_text)).to eq("plain text")
    end
  end

  describe "#truncate_text" do
    context "when text is shorter than max_width" do
      it "returns the text unchanged" do
        text = "short"
        expect(output.send(:truncate_text, text, 20)).to eq("short")
      end

      it "returns colored text unchanged" do
        text = "\e[38;5;34mshort\e[0m"
        expect(output.send(:truncate_text, text, 20)).to eq("\e[38;5;34mshort\e[0m")
      end
    end

    context "when text equals max_width" do
      it "returns the text unchanged" do
        text = "exact"
        expect(output.send(:truncate_text, text, 5)).to eq("exact")
      end
    end

    context "when text is longer than max_width" do
      it "truncates plain text and adds ellipsis" do
        text = "very long branch name"
        result = output.send(:truncate_text, text, 10)
        expect(result).to eq("very lo...")
        expect(output.send(:strip_ansi_codes, result).length).to eq(10)
      end

      it "truncates colored text and preserves color codes" do
        text = "\e[38;5;34mvery long branch name\e[0m"
        result = output.send(:truncate_text, text, 10)
        expect(result).to eq("\e[38;5;34mvery lo...\e[0m")
        expect(output.send(:strip_ansi_codes, result).length).to eq(10)
      end

      it "truncates bold colored text and preserves all color codes" do
        text = "\e[38;5;34m\e[1mvery long branch name\e[0m"
        result = output.send(:truncate_text, text, 10)
        expect(result).to eq("\e[38;5;34m\e[1mvery lo...\e[0m")
        expect(output.send(:strip_ansi_codes, result).length).to eq(10)
      end
    end

    context "when max_width is very small" do
      it "returns just ellipsis when max_width is less than 3" do
        text = "any text"
        expect(output.send(:truncate_text, text, 2)).to eq("...")
        expect(output.send(:truncate_text, text, 1)).to eq("...")
        expect(output.send(:truncate_text, text, 0)).to eq("...")
      end

      it "returns minimal truncation when max_width is exactly 3" do
        text = "any text"
        expect(output.send(:truncate_text, text, 3)).to eq("...")
      end

      it "returns minimal truncation when max_width is 4" do
        text = "any text"
        result = output.send(:truncate_text, text, 4)
        expect(result).to eq("a...")
      end
    end
  end

  describe "#terminal_width" do
    it "returns a positive integer" do
      width = output.send(:terminal_width)
      expect(width).to be_a(Integer)
      expect(width).to be > 0
    end

    it "returns at least 80 as default fallback" do
      allow(output).to receive(:`).with("tput cols 2>/dev/null").and_return("")
      stub_const("ENV", {})

      width = output.send(:terminal_width)
      expect(width).to eq(80)
    end

    it "uses COLUMNS environment variable when tput fails" do
      allow(output).to receive(:`).with("tput cols 2>/dev/null").and_return("")
      stub_const("ENV", { "COLUMNS" => "100" })

      width = output.send(:terminal_width)
      expect(width).to eq(100)
    end
  end

  describe "#calculate_max_branch_width" do
    it "returns a positive integer" do
      width = output.send(:calculate_max_branch_width)
      expect(width).to be_a(Integer)
      expect(width).to be > 0
    end

    it "ensures minimum width of 20 characters" do
      allow(output).to receive(:terminal_width).and_return(40)
      width = output.send(:calculate_max_branch_width)
      expect(width).to be >= 20
    end

    it "calculates appropriate width for standard 80-column terminal" do
      allow(output).to receive(:terminal_width).and_return(80)
      width = output.send(:calculate_max_branch_width)
      expect(width).to eq(49) # 80 - 31 fixed width
    end

    it "calculates appropriate width for wide terminal" do
      allow(output).to receive(:terminal_width).and_return(120)
      width = output.send(:calculate_max_branch_width)
      expect(width).to eq(89) # 120 - 31 fixed width
    end

    it "returns minimum width for narrow terminal" do
      allow(output).to receive(:terminal_width).and_return(30)
      width = output.send(:calculate_max_branch_width)
      expect(width).to eq(20) # minimum enforced
    end
  end

  describe "#branch_list" do
    let(:current_branch) { "master" }
    let(:branches) do
      [
        { "name" => "feature/very-long-branch-name-that-goes-on-and-on-and-on",
          "last_visited_at" => (Time.now - 300).to_s },
        { "name" => "master", "last_visited_at" => (Time.now - 3600).to_s },
        { "name" => "develop", "last_visited_at" => (Time.now - 86_400).to_s }
      ]
    end

    before do
      allow(output).to receive(:terminal_width).and_return(80)
    end

    it "outputs a table with truncated long branch names" do
      output_string = capture_stdout { output.branch_list(branches, current_branch) }
      expect(output_string).to match(/feature.*\.\.\./)
    end

    it "does not truncate short branch names" do
      output_string = capture_stdout { output.branch_list(branches, current_branch) }
      expect(output_string).to include("master")
      expect(output_string).to include("develop")
    end

    it "highlights current branch with color and marker" do
      output_string = capture_stdout { output.branch_list(branches, current_branch) }
      expect(output_string).to match(/→.*master/)
    end

    context "when quiet mode is enabled" do
      let(:quiet) { true }

      it "does not output anything" do
        output_string = capture_stdout { output.branch_list(branches, current_branch) }
        expect(output_string).to be_empty
      end
    end

    context "when branches list is empty" do
      let(:branches) { [] }

      it "does not output anything" do
        output_string = capture_stdout { output.branch_list(branches, current_branch) }
        expect(output_string).to be_empty
      end
    end

    context "with narrow terminal" do
      before do
        allow(output).to receive(:terminal_width).and_return(50)
      end

      it "truncates branch names more aggressively" do
        output_string = capture_stdout { output.branch_list(branches, current_branch) }
        expect(output_string).to include("...")
      end
    end

    context "with wide terminal" do
      before do
        allow(output).to receive(:terminal_width).and_return(150)
      end

      it "does not need to truncate short branch names" do
        short_branches = [
          { "name" => "master", "last_visited_at" => Time.now.to_s },
          { "name" => "develop", "last_visited_at" => Time.now.to_s }
        ]

        output_string = capture_stdout { output.branch_list(short_branches, current_branch) }
        expect(output_string).to include("master")
        expect(output_string).to include("develop")
        expect(output_string).not_to include("...") # No truncation for short names
      end
    end
  end

  describe "output methods" do
    context "when quiet mode is disabled" do
      let(:quiet) { false }

      it "#success outputs green message with checkmark" do
        output_string = capture_stdout { output.success("Done") }
        expect(output_string).to match(/✓/)
        expect(output_string).to include("Done")
      end

      it "#error outputs red message with X to stderr" do
        output_string = capture_stderr { output.error("Failed") }
        expect(output_string).to match(/✗/)
        expect(output_string).to include("Failed")
      end

      it "#warning outputs yellow message with warning symbol" do
        output_string = capture_stdout { output.warning("Careful") }
        expect(output_string).to match(/⚠/)
        expect(output_string).to include("Careful")
      end

      it "#info outputs blue message with info symbol" do
        output_string = capture_stdout { output.info("Notice") }
        expect(output_string).to match(/ℹ/)
        expect(output_string).to include("Notice")
      end
    end

    context "when quiet mode is enabled" do
      let(:quiet) { true }

      it "#success does not output" do
        output_string = capture_stdout { output.success("Done") }
        expect(output_string).to be_empty
      end

      it "#error still outputs to stderr" do
        output_string = capture_stderr { output.error("Failed") }
        expect(output_string).to include("Failed")
      end

      it "#warning does not output" do
        output_string = capture_stdout { output.warning("Careful") }
        expect(output_string).to be_empty
      end

      it "#info does not output" do
        output_string = capture_stdout { output.info("Notice") }
        expect(output_string).to be_empty
      end
    end

    context "when verbose mode is enabled" do
      let(:verbose) { true }

      it "#debug outputs dimmed message" do
        output_string = capture_stdout { output.debug("Debug info") }
        expect(output_string).to include("Debug info")
      end
    end

    context "when verbose mode is disabled" do
      let(:verbose) { false }

      it "#debug does not output" do
        output_string = capture_stdout { output.debug("Debug info") }
        expect(output_string).to be_empty
      end
    end
  end

  # Helper methods for capturing stdout/stderr
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end

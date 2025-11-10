# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitJump do
  it "has a version number" do
    expect(GitJump::VERSION).not_to be nil
  end
end

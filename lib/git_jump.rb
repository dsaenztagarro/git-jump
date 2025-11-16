# frozen_string_literal: true

# Minimal entry point - use specific loaders for optimized loading
# For backward compatibility and full library load
require_relative "git_jump/version"

# Only load XDG utilities by default (lightweight, commonly needed)
require_relative "git_jump/utils/xdg"

# For tests: Call GitJump.load_all! in your spec_helper.rb to load everything
# For production: Dependencies are loaded on-demand via action-specific loaders

# All other dependencies are loaded on-demand via loaders
# To use optimized loading in your code:
#   require "git_jump/loaders/add_loader"    # For add action
#   require "git_jump/loaders/list_loader"   # For list action
#   require "git_jump/loaders/jump_loader"   # For jump action
#   require "git_jump/loaders/clear_loader"  # For clear action
#   require "git_jump/loaders/install_loader" # For install action
#   require "git_jump/loaders/setup_loader"  # For setup action
#   require "git_jump/loaders/status_loader" # For status action

module GitJump
  class Error < StandardError; end

  # Manual full load trigger
  def self.load_all!
    return if @loaded_all

    require_relative "git_jump/colors"
    require_relative "git_jump/utils/output"
    require_relative "git_jump/utils/config_cache"
    require_relative "git_jump/config"
    require_relative "git_jump/database"
    require_relative "git_jump/repository"
    require_relative "git_jump/actions/base"
    require_relative "git_jump/actions/add"
    require_relative "git_jump/actions/list"
    require_relative "git_jump/actions/jump"
    require_relative "git_jump/actions/clear"
    require_relative "git_jump/actions/install"
    require_relative "git_jump/actions/setup"
    require_relative "git_jump/actions/status"
    require_relative "git_jump/hooks/post_checkout"
    require_relative "git_jump/cli"

    @loaded_all = true
  end
end

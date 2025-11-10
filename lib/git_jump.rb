# frozen_string_literal: true

require_relative "git_jump/version"

# Utilities
require_relative "git_jump/utils/xdg"
require_relative "git_jump/utils/output"

# Core
require_relative "git_jump/config"
require_relative "git_jump/database"
require_relative "git_jump/repository"

# Actions
require_relative "git_jump/actions/base"
require_relative "git_jump/actions/add"
require_relative "git_jump/actions/list"
require_relative "git_jump/actions/jump"
require_relative "git_jump/actions/clear"
require_relative "git_jump/actions/install"
require_relative "git_jump/actions/setup"
require_relative "git_jump/actions/status"

# Hooks
require_relative "git_jump/hooks/post_checkout"

# CLI
require_relative "git_jump/cli"

module GitJump
  class Error < StandardError; end
end

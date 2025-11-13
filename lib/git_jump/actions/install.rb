# frozen_string_literal: true

require_relative "base"

module GitJump
  module Actions
    # Action to install post-checkout git hook
    class Install < Base
      HOOK_TEMPLATE = <<~BASH
        #!/bin/sh
        # Git Jump post-checkout hook
        # Auto-generated - do not edit manually

        PREV_HEAD=$1
        NEW_HEAD=$2
        BRANCH_CHECKOUT=$3

        # Skip if called from git-jump itself to avoid double-loading
        if [ -n "$GIT_JUMP_SKIP_HOOK" ]; then
            exit 0
        fi

        # Only run on branch checkouts (not file checkouts)
        if [ "$BRANCH_CHECKOUT" = "1" ]; then
            RUBY_PATH="$(which ruby)"
        #{"    "}
            if [ -z "$RUBY_PATH" ]; then
                exit 0
            fi
        #{"    "}
            "$RUBY_PATH" -e "
              begin
                require 'git_jump'
                GitJump::Hooks::PostCheckout.new('$(pwd)').run
              rescue LoadError
                # Gem not available, skip silently
              rescue => e
                # Silent error handling in hook
              end
            " 2>/dev/null
        fi
      BASH

      def execute
        if repository.hook_installed?("post-checkout")
          existing_content = repository.read_hook("post-checkout")

          if existing_content&.include?("Git Jump post-checkout hook")
            output.info("Git Jump hook already installed")
            return true
          else
            output.warning("A post-checkout hook already exists")
            return false unless output.prompt("Overwrite existing hook?")
          end
        end

        repository.install_hook("post-checkout", HOOK_TEMPLATE)
        output.success("Installed post-checkout hook in #{repository.project_basename}")
        output.info("Branches will now be automatically tracked on checkout")

        true
      rescue StandardError => e
        output.error("Failed to install hook: #{e.message}")
        false
      end
    end
  end
end

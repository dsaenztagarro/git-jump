# frozen_string_literal: true

module GitJump
  module Actions
    # Action to initialize/setup configuration file
    class Setup
      attr_reader :config_path, :output

      def initialize(output:, config_path: nil, **_options)
        @config_path = config_path || Utils::XDG.config_path
        @output = output
      end

      def execute
        if File.exist?(@config_path)
          output.warning("Config file already exists at: #{@config_path}")
          return false unless output.prompt("Overwrite existing config?")
        end

        Utils::XDG.ensure_directories!

        File.write(@config_path, Config.default_config_content)

        output.success("Created config file at: #{@config_path}")
        output.info("Edit this file to customize your branch tracking settings")

        true
      rescue StandardError => e
        output.error("Failed to create config file: #{e.message}")
        false
      end
    end
  end
end

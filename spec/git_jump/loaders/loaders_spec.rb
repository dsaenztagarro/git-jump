# frozen_string_literal: true

RSpec.describe "Loaders" do
  # These constants are required by CLI#create_action for most commands
  REQUIRED_CONSTANTS = %w[
    GitJump::Config
    GitJump::Database
    GitJump::Repository
    GitJump::Utils::Output
  ].freeze

  # Map loader files to their action constants
  LOADERS = {
    "add_loader" => "GitJump::Actions::Add",
    "clear_loader" => "GitJump::Actions::Clear",
    "install_loader" => "GitJump::Actions::Install",
    "jump_loader" => "GitJump::Actions::Jump",
    "list_loader" => "GitJump::Actions::List",
    "status_loader" => "GitJump::Actions::Status"
  }.freeze

  LOADERS.each do |loader_name, action_constant|
    describe loader_name do
      before(:all) do
        # Use a fresh Ruby process to test loader in isolation
        @loader_path = File.expand_path("../../../lib/git_jump/loaders/#{loader_name}.rb", __dir__)
      end

      it "loads all required dependencies for create_action" do
        # Build a script that loads ONLY the loader and checks for required constants
        check_script = <<~RUBY
          # Start fresh - only load the loader
          require_relative "#{@loader_path}"

          missing = []
          #{REQUIRED_CONSTANTS.inspect}.each do |const|
            begin
              const.split("::").reduce(Object) { |mod, name| mod.const_get(name) }
            rescue NameError
              missing << const
            end
          end

          # Also check the action constant
          begin
            "#{action_constant}".split("::").reduce(Object) { |mod, name| mod.const_get(name) }
          rescue NameError
            missing << "#{action_constant}"
          end

          if missing.empty?
            exit 0
          else
            $stderr.puts "Missing constants: \#{missing.join(', ')}"
            exit 1
          end
        RUBY

        result = system("ruby", "-e", check_script, err: File::NULL)
        expect(result).to be(true), "#{loader_name} should load all required constants"
      end
    end
  end
end

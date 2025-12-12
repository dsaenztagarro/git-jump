# frozen_string_literal: true

RSpec.describe "Loaders" do
  let(:required_constants) do
    %w[
      GitJump::Config
      GitJump::Database
      GitJump::Repository
      GitJump::Utils::Output
    ]
  end

  let(:loaders) do
    {
      "add_loader" => "GitJump::Actions::Add",
      "clear_loader" => "GitJump::Actions::Clear",
      "install_loader" => "GitJump::Actions::Install",
      "jump_loader" => "GitJump::Actions::Jump",
      "list_loader" => "GitJump::Actions::List",
      "status_loader" => "GitJump::Actions::Status"
    }
  end

  loaders_to_test = {
    "add_loader" => "GitJump::Actions::Add",
    "clear_loader" => "GitJump::Actions::Clear",
    "install_loader" => "GitJump::Actions::Install",
    "jump_loader" => "GitJump::Actions::Jump",
    "list_loader" => "GitJump::Actions::List",
    "status_loader" => "GitJump::Actions::Status"
  }

  loaders_to_test.each do |loader_name, action_constant|
    describe loader_name do
      let(:loader_path) { File.expand_path("../../../lib/git_jump/loaders/#{loader_name}.rb", __dir__) }

      it "loads all required dependencies for create_action" do
        check_script = build_check_script(loader_path, action_constant)
        result = system("ruby", "-e", check_script, err: File::NULL)
        expect(result).to be(true), "#{loader_name} should load all required constants"
      end
    end
  end

  def build_check_script(loader_path, action_constant)
    required_constants = %w[
      GitJump::Config
      GitJump::Database
      GitJump::Repository
      GitJump::Utils::Output
    ]

    <<~RUBY
      require_relative "#{loader_path}"

      missing = []
      #{required_constants.inspect}.each do |const|
        begin
          const.split("::").reduce(Object) { |mod, name| mod.const_get(name) }
        rescue NameError
          missing << const
        end
      end

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
  end
end

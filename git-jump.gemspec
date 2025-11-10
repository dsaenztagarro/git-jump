# frozen_string_literal: true

require_relative "lib/git_jump/version"

Gem::Specification.new do |spec|
  spec.name = "git-jump"
  spec.version = GitJump::VERSION
  spec.authors = ["David Sáenz"]
  spec.email = ["dsaenz@bebanjo.com"]

  spec.summary = "Smart git branch tracker and switcher with SQLite persistence"
  spec.description = "Git::Jump tracks your git branches across projects and provides quick branch switching. " \
                     "It uses a SQLite database to remember your branch history and integrates with git hooks " \
                     "for automatic tracking."
  spec.homepage = "https://github.com/dsaenztagarro/git-jump"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dsaenztagarro/git-jump"
  spec.metadata["changelog_uri"] = "https://github.com/dsaenztagarro/git-jump/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "sqlite3", "~> 1.7"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "toml-rb", "~> 2.2"
  spec.add_dependency "tty-table", "~> 0.12"

  spec.add_development_dependency "rake", "~> 13.3.0"
  spec.add_development_dependency "rspec", "~> 3.13.1"
  spec.add_development_dependency "rubocop", "~> 1.81.1"
  spec.add_development_dependency "rubocop-rspec", "~> 3.7.0"
  spec.add_development_dependency "ruby-lsp", "~> 0.26.1"
end

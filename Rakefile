# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :release do
  desc "Tag git with the current GitJump::VERSION"
  task :tag do
    require_relative "lib/git_jump/version"
    version = GitJump::VERSION
    tag_name = "v#{version}"

    # Check if tag already exists
    if `git tag --list`.split.include?(tag_name)
      puts "Tag #{tag_name} already exists."
      exit(1)
    end

    puts "Tagging commit as #{tag_name}..."
    sh "git tag -a #{tag_name} -m 'Release #{tag_name}'"
    puts "Pushing tag #{tag_name} to origin..."
    sh "git push origin #{tag_name}"
    puts "Done!"
  end
end

# Agent Guidelines for git-jump

## Build/Test/Lint Commands
- Setup: `bin/setup` or `bundle install`
- Run all tests: `rake spec` or `bundle exec rspec`
- Run single test file: `bundle exec rspec spec/path/to/file_spec.rb`
- Run single test: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- Lint: `rake rubocop` or `bundle exec rubocop`
- Lint autofix: `bundle exec rubocop -a`
- Default task (tests + lint): `rake`

## Code Style Guidelines
- **Ruby version**: >= 3.2.0
- **Frozen string literal**: Add `# frozen_string_literal: true` to top of every .rb file
- **String literals**: Use double quotes for all strings (enforced by RuboCop)
- **Imports**: Use `require_relative` for internal files, `require` for gems. Optimize loading via loaders for CLI actions
- **Naming**: Use snake_case for methods/variables, PascalCase for classes/modules
- **Documentation**: Class/module documentation comments disabled (no need for YARD-style docs)
- **Error handling**: Return false for errors in actions, output error messages via `output.error()`
- **Dependencies**: All actions inherit from `Actions::Base`, accept `config:`, `database:`, `repository:`, `output:` kwargs
- **Tests**: Use RSpec with `subject(:action)`, `let` helpers, and `instance_double` for mocking. Setup git repos in temp dirs
- **Modules**: Namespace everything under `GitJump` or `GitJump::Actions`, `GitJump::Utils`, etc.

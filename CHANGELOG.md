## [Unreleased]

## [0.1.3] - 2025-12-12

### Fixed
- Fixed post-checkout hook to work correctly across all projects
  - Hook now properly requires 'git_jump/hooks/post_checkout' instead of 'git_jump'
  - Added missing dependency requires to post_checkout.rb (Repository, Config, Database)
  - Added missing require for Utils::XDG in config.rb
  - Hook now respects .ruby-version files in repositories
- Fixed install_loader to include Database dependency

### Added
- Comprehensive test suite for post-checkout hook (17 tests)
  - Tests for branch tracking, project creation, error handling
  - Hook template validation tests
  - Dependency loading verification tests
- Added loader tests to ensure all dependencies are properly loaded (6 tests)
- Added local testing documentation in docs/local-testing.md

### Changed
- Improved code quality by fixing all RuboCop offenses
- Extracted helper methods in specs for better maintainability

## [0.1.2] - 2025-11-16

### Fixed
- Fixed setup action error handling and loader dependencies

## [0.1.1] - 2025-11-16

### Changed
- Replaced Thor with OptionParser for CLI parsing
  - Reduced runtime dependencies from 4 to 3
  - Improved CLI startup time by 56% (from ~1.6s to ~0.7s)
  - Eliminated 296KB Thor gem dependency
  - All commands and options remain fully functional

## [0.1.0] - 2025-11-03

- Initial release

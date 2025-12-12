# Testing git-jump Locally Before Release

This guide explains how to test git-jump in local projects before releasing a new version to RubyGems.

## Prerequisites

- Ruby >= 3.2.0
- Bundler installed (`gem install bundler`)

## Method 1: Using `bundle exec rake install`

This installs the gem locally on your system:

```bash
# From the git-jump directory
cd /path/to/git-jump

# Install dependencies
bundle install

# Build and install the gem locally
bundle exec rake install
```

After running this, `git-jump` will be available system-wide. You can test it in any project:

```bash
cd /path/to/your/test-project
git-jump status
git-jump list
```

## Method 2: Using `gem build` + `gem install`

Build the gem manually and install it:

```bash
# From the git-jump directory
cd /path/to/git-jump

# Build the gem
gem build git-jump.gemspec

# Install the built gem (version will match lib/git_jump/version.rb)
gem install ./git-jump-*.gem
```

## Method 3: Using Bundler's Path Option (Recommended for Development)

Add git-jump to a test project's Gemfile using the local path:

```ruby
# In your test project's Gemfile
gem "git-jump", path: "/path/to/git-jump"
```

Then run:

```bash
cd /path/to/your/test-project
bundle install
bundle exec git-jump status
```

This method is useful because:
- Changes to the source code are immediately available
- No need to rebuild/reinstall after each change
- Isolated to the specific project

## Method 4: Direct Execution from Source

Run git-jump directly from the source directory without installing:

```bash
# From the git-jump directory
cd /path/to/git-jump

# Run using the exe script
bundle exec exe/git-jump status

# Or run in a different directory
bundle exec exe/git-jump --help
```

To test in another project directory:

```bash
cd /path/to/your/test-project
/path/to/git-jump/bin/git-jump list
```

## Running Tests Before Local Testing

Always run the test suite before testing locally:

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage
bundle exec rspec

# Run linter
bundle exec rubocop

# Run both tests and linter
bundle exec rake
```

## Testing Checklist

Before releasing, verify these commands work correctly:

1. **Setup**: `git-jump setup` - Creates config file
2. **Install hook**: `git-jump install` - Installs post-checkout hook
3. **Add branch**: `git-jump add <branch-name>` - Adds branch to tracking
4. **List branches**: `git-jump list` - Shows tracked branches
5. **Jump**: `git-jump jump` - Switches to next branch
6. **Jump by index**: `git-jump jump 2` - Switches to branch at index
7. **Clear**: `git-jump clear` - Clears non-kept branches
8. **Status**: `git-jump status` - Shows current status
9. **Version**: `git-jump version` - Shows version number

## Testing the Post-Checkout Hook

After installing the hook with `git-jump install`:

```bash
# Check the hook exists
cat .git/hooks/post-checkout

# Test by checking out branches
git checkout -b test-branch-1
git checkout -b test-branch-2
git checkout main

# Verify branches were tracked
git-jump list
```

## Cleaning Up After Testing

To remove the locally installed gem:

```bash
gem uninstall git-jump
```

To remove git-jump data:

```bash
# Remove config
rm -rf ~/.config/git-jump

# Remove database
rm -rf ~/.local/share/git-jump

# Or if using custom XDG paths
rm -rf $XDG_CONFIG_HOME/git-jump
rm -rf $XDG_DATA_HOME/git-jump
```

## Troubleshooting

### Gem not found after installation

Make sure the gem's bin directory is in your PATH:

```bash
gem environment | grep "EXECUTABLE DIRECTORY"
```

### Changes not reflected

If using Method 1 or 2, you need to rebuild and reinstall after making changes:

```bash
bundle exec rake install
```

### Database errors

Delete the SQLite database and start fresh:

```bash
rm ~/.local/share/git-jump/branches.db
```

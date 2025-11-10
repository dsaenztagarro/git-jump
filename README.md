# Git::Jump

A CLI tool for tracking and quickly switching between git branches across projects. Git::Jump automatically tracks your branch history and lets you jump between recently visited branches with ease.

## Features

- **Automatic Branch Tracking**: Install a git hook to automatically track branches when you check them out
- **Manual Branch Management**: Add, list, and clear tracked branches
- **Quick Branch Switching**: Jump to the next branch or a specific branch by index
- **Smart Branch Ordering**: Branches are ordered by most recently visited
- **Project-Specific Tracking**: Separate branch history for each git repository
- **Configurable Keep Patterns**: Define which branches to keep when clearing (e.g., main, master, develop)
- **XDG Base Directory Support**: Configuration and data files follow XDG standards
- **Beautiful Terminal Output**: Colored output and formatted tables for easy reading

## Installation

Install the gem by executing:

```bash
gem install git-jump
```

Or add it to your application's Gemfile:

```bash
bundle add git-jump
```

## Quick Start

1. Initialize the configuration file:
```bash
git-jump setup
```

2. Navigate to a git repository and install the post-checkout hook:
```bash
cd /path/to/your/repo
git-jump install
```

3. Now branches will be automatically tracked when you check them out! Or add branches manually:
```bash
git-jump add feature/my-branch
```

4. List tracked branches:
```bash
git-jump list
```

5. Jump to the next branch in the list:
```bash
git-jump jump
```

6. Or jump to a specific branch by index:
```bash
git-jump jump 3
```

## Usage

### Commands

#### `git-jump setup`
Initialize the configuration file at `~/.config/git-jump/config.toml` (or `$XDG_CONFIG_HOME/git-jump/config.toml`).

```bash
git-jump setup
```

#### `git-jump install`
Install the post-checkout git hook in the current repository. This enables automatic branch tracking whenever you checkout a branch.

```bash
cd /path/to/your/repo
git-jump install
```

#### `git-jump add BRANCH`
Manually add a branch to tracking for the current project.

```bash
git-jump add feature/my-branch
```

#### `git-jump list`
List all tracked branches for the current project. Branches are displayed with an index number and sorted by most recently visited.

```bash
git-jump list
```

Output example:
```
Tracked Branches
────────────────
┌─────┬────────────────┬──────────────┐
│ #   │ Branch         │ Last Visited │
├─────┼────────────────┼──────────────┤
│ → 1 │ feature/auth   │ just now     │
│   2 │ feature/api    │ 2 hours ago  │
│   3 │ master         │ 1 day ago    │
└─────┴────────────────┴──────────────┘
```

#### `git-jump jump [INDEX]`
Jump to the next branch in the list, or to a specific branch by index.

```bash
# Jump to the next branch
git-jump jump

# Jump to branch at index 3
git-jump jump 3
```

#### `git-jump clear`
Clear branches that don't match the keep patterns defined in your configuration. This is useful for cleaning up old feature branches while preserving important branches like main, master, etc.

```bash
git-jump clear
```

You'll be prompted to confirm before clearing.

#### `git-jump status`
Show the current status, configuration, and tracking statistics.

```bash
git-jump status
```

Output example:
```
Git Jump Status
───────────────
ℹ Project: my-project
ℹ Path: /Users/me/code/my-project
ℹ Current branch: feature/auth

Configuration
─────────────
ℹ Config file: /Users/me/.config/git-jump/config.toml
ℹ Config exists: Yes
ℹ Database: /Users/me/.local/share/git-jump/branches.db
ℹ Max branches: 20
ℹ Auto-track: Enabled
ℹ Keep patterns: ^main$, ^master$, ^develop$, ^staging$

Hook Status
───────────
ℹ Post-checkout hook: Installed

Tracking Statistics
───────────────────
ℹ Total branches tracked: 5
ℹ Most recent: feature/auth
```

#### `git-jump version`
Show the current version of git-jump.

```bash
git-jump version
```

### Global Options

All commands support these global options:

- `--config PATH` or `-c PATH`: Use a custom configuration file
- `--quiet` or `-q`: Suppress output
- `--verbose` or `-v`: Enable verbose output

Example:
```bash
git-jump --config ~/my-config.toml list
git-jump -q jump
git-jump -v status
```

## Configuration

Git::Jump uses a TOML configuration file located at `~/.config/git-jump/config.toml` (or `$XDG_CONFIG_HOME/git-jump/config.toml`).

Run `git-jump setup` to create the default configuration file.

### Configuration Options

```toml
[database]
# SQLite database location (defaults to XDG_DATA_HOME/git-jump/branches.db)
# You can use environment variables like $XDG_DATA_HOME or $HOME
path = "$XDG_DATA_HOME/git-jump/branches.db"

[tracking]
# Maximum number of branches to track per project
max_branches = 20

# Automatically track branches on checkout (via git hook)
auto_track = true

# Global branch patterns to always keep when clearing (regex patterns)
keep_patterns = ["^main$", "^master$", "^develop$", "^staging$"]

# Example project-specific configuration
# [[projects]]
# name = "my-project"
# path = "/path/to/my-project"
# keep_patterns = ["^main$", "^feature/.*$"]
```

### Keep Patterns

Keep patterns are regex patterns that define which branches should be preserved when running `git-jump clear`. By default, common main branches are kept:

- `^main$` - main branch
- `^master$` - master branch
- `^develop$` - develop branch
- `^staging$` - staging branch

You can customize these patterns globally or per-project in your configuration file.

### XDG Base Directory Support

Git::Jump follows the XDG Base Directory Specification:

- **Configuration**: `$XDG_CONFIG_HOME/git-jump/config.toml` (defaults to `~/.config/git-jump/config.toml`)
- **Data**: `$XDG_DATA_HOME/git-jump/branches.db` (defaults to `~/.local/share/git-jump/branches.db`)
- **Cache**: `$XDG_CACHE_HOME/git-jump/` (defaults to `~/.cache/git-jump/`)

## Usage Examples

### Typical Workflow

```bash
# First time setup
git-jump setup

# In your project directory
cd ~/code/my-project
git-jump install

# Work on different branches
git checkout feature/authentication
git checkout feature/api
git checkout feature/ui

# List your tracked branches
git-jump list
# Output:
# Tracked Branches
# ────────────────
# ┌─────┬─────────────────────────┬──────────────┐
# │ #   │ Branch                  │ Last Visited │
# ├─────┼─────────────────────────┼──────────────┤
# │ → 1 │ feature/ui              │ just now     │
# │   2 │ feature/api             │ 5 minutes ago│
# │   3 │ feature/authentication  │ 10 minutes ago│
# └─────┴─────────────────────────┴──────────────┘

# Jump to the next branch (feature/api)
git-jump jump

# Jump to a specific branch by index
git-jump jump 3  # Switches to feature/authentication

# Clean up old feature branches (keeps main/master/develop/staging)
git-jump clear
```

### Working Across Multiple Projects

Git::Jump tracks branches per project, so you can use it across all your repositories:

```bash
# Project A
cd ~/code/project-a
git-jump install
git checkout feature/new-ui
git checkout feature/refactor

# Project B
cd ~/code/project-b
git-jump install
git checkout bugfix/login
git checkout feature/dashboard

# Each project maintains its own branch history
cd ~/code/project-a
git-jump list  # Shows only project-a branches

cd ~/code/project-b
git-jump list  # Shows only project-b branches
```

### Using Custom Configuration

```bash
# Use a custom config file
git-jump --config ~/my-custom-config.toml status

# Run commands quietly (no output)
git-jump -q jump

# Verbose output for debugging
git-jump -v add feature/new-feature
```

## How It Works

Git::Jump tracks your branch history in a SQLite database. Each time you check out a branch (with the hook installed) or manually add a branch, it's recorded in the database with:

- Project path and name
- Branch name
- Last visited timestamp
- Position in the branch list

Branches are automatically reordered based on when they were last visited, so the most recently used branches appear at the top of the list. This makes it easy to jump between branches you're actively working on.

When you run `git-jump jump`, it checks out the next branch in the list (or the branch at the specified index) and updates the last visited timestamp, moving it to the top of the list.

### Post-Checkout Hook

When you run `git-jump install`, it creates a post-checkout hook in `.git/hooks/post-checkout` that automatically tracks branches when you check them out using `git checkout`. The hook is safe and will not interfere with existing hooks if you chain them properly.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dsaenzriv/git-jump. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dsaenzriv/git-jump/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Git::Jump project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dsaenzriv/git-jump/blob/master/CODE_OF_CONDUCT.md).

## Acknowledgments

Inspired by the need to quickly switch between feature branches during development. Architecture follows the modular design patterns from [dotsync](https://github.com/dotboris/dotsync).

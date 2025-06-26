# Command Directory

This directory contains custom commands and utilities for the development environment.

## Structure
- `scripts/` - Utility scripts
- `tools/` - Development tools and helpers
- `git/` - Git-related commands
- `system/` - System administration commands

## Usage
Commands in this directory are automatically added to PATH via the shell configuration.

## Adding New Commands
1. Create executable scripts in the appropriate subdirectory
2. Make them executable: `chmod +x script_name`
3. Reload shell: `source ~/.zshrc`

## Examples
- `git/git-cleanup` - Clean up merged branches
- `system/backup-dotfiles` - Backup configuration files
- `tools/dev-setup` - Development environment setup
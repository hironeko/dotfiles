# Claude Code Memory

This file contains context and memory for Claude Code sessions.

## Project Structure
This is a dotfiles repository for managing development environment configurations.

## Key Directories:
- `bin/`: Contains alias and path configurations
- `functions/`: Custom shell functions (AWS, Git worktree, etc.)
- `command/`: Custom commands and utilities
- `.claude/`: Claude Code configuration
- `shared-tasks/`: Multi-agent task management

## Development Environment:
- Shell: zsh with custom configuration
- Terminal multiplexer: tmux with Nordic-style theme
- Package managers: brew, anyenv, volta
- Version control: Git with worktree support

## Recent Updates:
- Implemented Powerlevel10k theme for beautiful prompts with Powerline arrows
- Modernized tmux status bar with blue Nordic color scheme and Powerline design
- Added Nerd Fonts support (Hack, FiraCode, MesloLG)
- Cleaned up .zshrc removing custom prompt code (now using p10k)
- Added case-insensitive completion for better usability

## Commands to Run:
When making changes to shell configurations, always test with:
```bash
source ~/.zshrc
tmux source-file ~/.tmux.conf
```

## Lint/Type Check Commands:
No specific linting commands configured yet for shell scripts.
Consider adding shellcheck for bash/zsh script validation.
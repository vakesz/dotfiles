# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a cross-platform dotfiles repository managed with GNU Stow, supporting macOS, Linux, and WSL. The setup follows XDG Base Directory specification and uses a centralized package management system via `scripts/packages.json`.

## Installation and Setup

### Initial Installation

```bash
./install.sh
```

The install script:
1. Detects OS (macOS/Linux/WSL)
2. Installs package manager (Homebrew on macOS)
3. Parses `scripts/packages.json` and installs packages via appropriate managers
4. Sets up XDG directories
5. Backs up existing dotfiles to `~/.dotfiles_backup_<timestamp>/`
6. Symlinks dotfiles using GNU Stow
7. Sets Zsh as default shell
8. Runs platform-specific setup scripts

### Managing Dotfiles with Stow

```bash
# Symlink dotfiles
stow .

# Remove symlinks
stow -D .

# Re-adopt changes from home directory
stow --adopt .
```

Stow uses `.stow-local-ignore` to exclude files like README.md, scripts/, .git/, etc.

## Package Management

### Adding New Packages

Edit `scripts/packages.json`:

```json
{
  "name": "package-name",
  "brew": "package-name",           # macOS via Homebrew
  "apt": "package-name",             # Linux via apt
  "cargo": "package-name",           # Rust cargo
  "pip": "package-name",             # Python pip
  "npm": "package-name",             # Node npm
  "manual": "curl ... | bash",       # Manual installation command
  "description": "What it does"
}
```

The install script uses `jq` to parse this file and install packages based on platform.

### Package Categories

- `core`: git, curl, wget, stow
- `shell`: zsh, tmux, fzf, ripgrep, fd, bat, zoxide, oh-my-posh
- `editors`: neovim, shellcheck
- `languages`: python@3.13, node@22, go, rust
- `tools`: jq, tree-sitter, git-delta, tig, httpie, pre-commit
- `build`: cmake, make, gcc
- `formatters`: prettier, stylua, ruff

## Zsh Configuration Architecture

### XDG Compliance

- `ZDOTDIR` set to `~/.config/zsh` via `.zshenv` in home directory
- All Zsh files live in `~/.config/zsh/`
- History stored in `~/.local/state/zsh/`

### Configuration Loading Order

`.zshrc` sources modules from `config.d/` in this order:

1. `platform.zsh` - OS detection (`is_mac`, `is_wsl`, `is_linux`) and `have` command checker
2. `path.zsh` - Platform-specific PATH setup (Homebrew paths, cargo, local bins)
3. `env.zsh` - Environment variables (EDITOR, VISUAL, XDG vars)
4. `plugins.zsh` - Zinit plugin manager and plugins
5. `completion.zsh` - Zsh completion system configuration
6. `aliases.zsh` - Platform-specific aliases and functions
7. Oh My Posh prompt initialization

### Zinit Plugin Management

Plugins installed via Zinit (stored in `~/.local/share/zinit/`):
- zsh-syntax-highlighting
- zsh-autosuggestions
- zsh-completions
- fzf-tab

OMZ snippets: git, sudo, command-not-found, docker (if installed)

### Platform Detection

Use these helper functions in Zsh configs:
- `is_mac` - Returns true on macOS
- `is_wsl` - Returns true on WSL
- `is_linux` - Returns true on Linux (non-WSL)
- `have <command>` - Checks if command exists

Example:
```bash
if is_mac; then
  alias ll="ls -lah"
elif is_linux; then
  alias ll="ls -lah --color=auto"
fi
```

## Neovim Configuration

- Entry point: `.config/nvim/init.lua` requires `vakesz` module
- Main config: `.config/nvim/lua/vakesz/`
  - `init.lua` - Main initialization
  - `lazy_init.lua` - Lazy.nvim plugin manager setup
  - `lazy/` - Individual plugin configurations
  - `remap.lua` - Key mappings
  - `set.lua` - Vim settings

Uses Lazy.nvim for plugin management with modular plugin configs.

## Platform-Specific Setup

### macOS (`scripts/mac.sh`)
- Sets up Homebrew environment
- Configures macOS-specific settings
- Handles keg-only packages (python@3.13, node@22)

### WSL (`scripts/wsl.sh`)
- Installs Rust toolchain
- Sets up cargo packages
- Configures WSL-specific environment

## Development Workflow

### Making Changes

1. Edit files in `.config/` or root dotfiles
2. Changes are immediately reflected (files are symlinked)
3. Test across platforms if making platform-specific changes
4. Commit changes to git

### Testing Changes

```bash
# Test on macOS
./install.sh

# Test Zsh config reload
exec zsh

# Test stow operations
stow -D . && stow .
```

### Adding Configuration Files

1. Add files to appropriate `.config/<app>/` directory
2. Update `.stow-local-ignore` if needed
3. Run `stow .` to create symlinks

## Git Configuration

- Global gitconfig: `.gitconfig` (symlinked to `~/.gitconfig`)
- Git-specific config: `.config/git/` (contains additional git configs)
- Uses git-delta for better diffs (if installed)

## Important Paths

- XDG Config: `~/.config`
- XDG Data: `~/.local/share`
- XDG State: `~/.local/state`
- XDG Cache: `~/.cache`
- Zinit: `~/.local/share/zinit/`
- Zsh History: `~/.local/state/zsh/history`

## Common Issues

### Stow Conflicts
Install script automatically backs up conflicts to `~/.dotfiles_backup_<timestamp>/`

### Missing Commands on Linux
Some packages (oh-my-posh, rust tools) need manual installation via `manual` field in packages.json

### keg-only Packages (macOS)
Homebrew keg-only packages (python@3.13, node@22) need PATH setup in `path.zsh`

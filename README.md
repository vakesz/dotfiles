# Dotfiles

Cross-platform dotfiles for macOS, Linux, and WSL. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Installation

```bash
./install.sh
```

Dry-run (preview without changes):
```bash
DOTFILES_STOW_SIMULATE=1 ./install.sh
```

**Prerequisites:** Install GNU Stow first (`brew install stow` or `apt install stow`).

## What's Included

### Shell
- **Zsh** with XDG-compliant setup
- **Oh My Posh** prompt
- **Zinit** plugin manager

### Neovim
- **lazy.nvim** package manager
- **Mason** for LSP/formatters
- **Telescope** fuzzy finder
- **nvim-cmp** completion with Copilot
- **conform.nvim** formatting
- **fugitive + gitsigns** Git integration

See [KEYMAPS.md](KEYMAPS.md) for keybindings.

### Other
- **tmux** configuration
- **Git** config and global ignore
- **topgrade** update tool config

## Structure

```
dotfiles/
├── .config/
│   ├── git/              # Global gitignore
│   ├── nvim/             # Neovim config
│   ├── oh-my-posh/       # Prompt theme
│   ├── tmux/             # tmux config
│   ├── topgrade.toml     # Update tool
│   └── zsh/              # Zsh config
├── .gitconfig            # Git settings
├── .zshenv               # Sets ZDOTDIR
└── install.sh            # Installer
```

## XDG Compliance

Configs use XDG Base Directory spec to keep `$HOME` clean:
- `~/.config` - configs
- `~/.local/share` - data
- `~/.local/state` - history

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Oh My Posh](https://ohmyposh.dev/)

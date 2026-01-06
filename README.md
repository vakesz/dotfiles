# Dotfiles

Cross-platform dotfiles for macOS, Linux, and WSL. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Installation

```bash
./install.sh
```

**Prerequisites:** GNU Stow (`brew install stow` or `apt install stow`), Neovim 0.10+ for the nvim config

### OS Tweaks (Optional)

The installer prompts to apply platform-specific settings:

**macOS:**
- Finder: show hidden files, extensions, path bar, list view, folders first
- Keyboard: fast key repeat, disable auto-correct/substitution
- Dock: smaller tiles, scale effect
- Trackpad: tap to click
- Screenshots: save to Desktop as PNG
- Disable Tips notifications

**Linux/WSL:**
- Configure en_US.UTF-8 locale (Debian/Ubuntu, Fedora/RHEL, Arch)
- Set zsh as default shell

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
- **fd** fast find alternative config
- **ripgrep** fast grep alternative config
- **topgrade** update tool config

## Structure

```
dotfiles/
├── .config/
│   ├── fd/               # fd (find alternative) config
│   ├── git/              # Global gitignore
│   ├── nvim/             # Neovim config
│   ├── oh-my-posh/       # Prompt theme
│   ├── ripgrep/          # ripgrep config
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

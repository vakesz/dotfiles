# Dotfiles

Cross-platform dotfiles for macOS, Linux, and WSL.

## Installation

```bash
# Install packages (macOS)
brew bundle install

# Create symlinks (uses GNU Stow)
./install.sh
```

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
- **tealdeer** tldr client config
- **topgrade** update tool config

## Structure

```tree
dotfiles/
├── home/                 # stow -t ~ (root dotfiles)
│   └── .zshenv           # Sets ZDOTDIR
├── config/               # stow -t ~/.config
│   ├── fd/               # fd (find alternative) config
│   ├── git/
│   │   ├── config        # Git settings
│   │   └── ignore        # Global gitignore
│   ├── nvim/             # Neovim config
│   ├── oh-my-posh/       # Prompt theme
│   ├── ripgrep/          # ripgrep config
│   ├── tealdeer/         # tldr client config
│   ├── tmux/             # tmux config
│   ├── topgrade.toml     # Update tool
│   └── zsh/              # Zsh config
├── apps/                 # Not stowed (iTerm themes, etc.)
├── Brewfile              # Homebrew packages
└── install.sh            # Installer (uses GNU Stow)
```

## XDG Compliance

Configs use XDG Base Directory spec to keep `$HOME` clean:
- `~/.config` - configs
- `~/.local/share` - data
- `~/.local/state` - history

## Update Strategy

All updates run through `topgrade`. Apps have auto-update disabled; topgrade handles them via `brew upgrade --greedy-auto-updates`.

| Category | What | Method |
|----------|------|--------|
| Packages | Homebrew formulae/casks | Native (greedy mode) |
| Packages | Mac App Store | Native (mas) |
| Shell | Zinit plugins | Custom command |
| Editor | Neovim plugins | Custom command |
| Python | UV tools | Custom command |
| GitHub | gh extensions | Custom command |
| System | Firmware | Native |

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/) - Symlink farm manager
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Oh My Posh](https://ohmyposh.dev/)

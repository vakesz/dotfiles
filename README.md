# Dotfiles Setup

Cross-platform dotfiles that bootstrap a productive development environment using Homebrew. Works seamlessly on macOS, Linux, and WSL2.

## ✨ Features

- **Cross-Platform**: Single setup works on macOS, Linux, and WSL2
- **Homebrew-Powered**: Unified package management across all platforms
- **Symlinked Configs**: Live-updating dotfiles - changes sync automatically
- **Idempotent**: Safe to re-run anytime for updates
- **Modular Design**: Clean, maintainable architecture

## 🚀 Quick Start

```bash
git clone https://github.com/vakesz/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

Restart your shell: `exec $SHELL`

## 📁 Repository Structure

```text
dotfiles/
├── Brewfile                    # All packages via Homebrew
├── install.sh                  # Main installer script
├── lib/                        # Modular utilities
│   ├── brew.sh                 # Homebrew management
│   ├── platform.sh             # OS detection & logging
│   └── symlink.sh              # Symlinking logic
├── config/                     # Dotfiles (symlinked to ~/)
│   ├── .gitconfig
│   ├── .zshrc
│   ├── .tmux.conf
│   └── .config/
│       ├── nvim/               # Neovim configuration
│       └── .p10k.zsh           # Powerlevel10k theme
└── README.md
```

## 🛠 Development Stack

### Core Tools

- **Shell**: Zsh with Starship prompt + modern plugins
- **Editor**: Neovim with extensive plugin setup
- **Terminal**: tmux with custom configuration
- **Version Control**: Git with helpful aliases

### Languages & Runtimes

- Node.js (with pnpm)
- Python 3.11 (with pipx)
- Rust (with cargo)
- Go
- Zig
- Java (OpenJDK 21)
- Ruby
- Lua

### Development Tools

- Docker & Docker Compose
- GitHub CLI (gh)
- Various linters: shellcheck, prettier, eslint, black, ruff
- Build tools: cmake, make, ninja, gcc, llvm

### CLI Utilities

- Modern replacements: `lsd`, `bat`, `fd`, `ripgrep`
- System tools: `htop`, `tree`, `jq`, `httpie`, `nmap`
- Development: `fzf`, `tig`, `tldr`, `pre-commit`

## 💻 Usage

### Installation Options

```bash
# Full installation (recommended)
./install.sh

# Update existing setup
./install.sh --update

# Skip package installation (configs only)
./install.sh --skip-packages

# Skip symlinking (packages only)
./install.sh --skip-symlinks

# Clean up broken symlinks
./install.sh --cleanup

# Show help
./install.sh --help
```

### Adding New Packages

Simply edit `Brewfile` and add your package:

```ruby
# Add a CLI tool
brew "your-package"

# Add a desktop app (macOS only)
cask "your-app" if OS.mac?

# Add from a tap
tap "owner/repo"
brew "special-package"
```

Then run: `./install.sh --update`

### Customizing Configs

All configs are in `config/` and automatically symlinked to your home directory. Make changes directly in the repo - they'll be reflected immediately since they're symlinked.

## 🔧 Platform-Specific Notes

### macOS

- Uses `/opt/homebrew` on Apple Silicon, `/usr/local` on Intel
- Installs GUI applications via Homebrew casks
- Includes Nerd Font installation

### Linux/WSL

- Installs Homebrew to `/home/linuxbrew/.linuxbrew`
- Sets up proper locale configuration for WSL2
- Handles font installation via fontconfig
- Installs build essentials automatically

## 🔄 Maintenance

### Keep Everything Updated

```bash
cd ~/.dotfiles
git pull
./install.sh --update
```

### Manage Homebrew

```bash
# Update package list
brew bundle dump --force

# Check what would be installed/removed
brew bundle --dry-run

# Clean up
brew cleanup
```

## 🗂 Migration Guide

If migrating from the old apt-based setup:

1. **Backup**: The installer automatically backs up existing configs
2. **Run**: Execute `./install.sh` - it handles the migration
3. **Verify**: Check that symlinks are working: `ls -la ~/ | grep -E '\->'`
4. **Cleanup**: Remove old installation files when satisfied

## 🆘 Troubleshooting

### Broken Symlinks

```bash
./install.sh --cleanup
```

### Permission Issues

```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Missing Dependencies

```bash
# Reinstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
./install.sh
```

## 📝 License

Personal configuration repository. Fork and adapt as needed.

---
Happy coding! 🎯

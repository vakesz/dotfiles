# Dotfiles

Personal dotfiles for macOS and Linux development environments, managed with GNU Stow.

Cross-platform setup using Homebrew for package management and GNU Stow for symlink management. Works seamlessly on macOS, Linux, and WSL2.

## 🚀 Quick Start

```bash
git clone https://github.com/vakesz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## 📁 Repository Structure

```text
dotfiles/
├── zsh/                        # Zsh shell configuration
│   ├── .zshrc                 # Main zsh config
│   └── .zshrc.d/              # Modular config directory (add custom modules here)
├── git/                        # Git configuration
│   ├── .gitconfig             # Main git config
│   ├── .gitconfig.macos       # macOS-specific (Keychain credentials)
│   ├── .gitconfig.linux       # Linux-specific (cache credentials)
│   └── .gitignore_global      # Global gitignore
├── nvim/                       # Neovim configuration
│   └── .config/nvim/          # Neovim config directory
├── tmux/                       # Tmux configuration
│   └── .tmux.conf
├── starship/                   # Starship prompt
│   └── .config/starship.toml
├── shell-profile/              # Shell profile
│   └── .profile
├── lib/                        # Helper libraries
│   ├── platform.sh            # Platform detection
│   ├── brew.sh                # Homebrew utilities
│   ├── symlink.sh             # Symlink management
│   └── permissions.sh         # Security utilities
├── Brewfile                    # All packages via Homebrew
├── bootstrap.sh                # Simple installer
└── README.md
```

Each top-level directory (`zsh`, `git`, `nvim`, etc.) is a **Stow package** that can be installed independently.

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

## 💻 Usage

### Installation

```bash
# Full installation (recommended)
./bootstrap.sh

# Or install packages individually with Stow
cd ~/dotfiles
stow zsh git nvim tmux starship shell-profile

# Install only specific packages
stow zsh git  # Just shell and git configs

# Uninstall/remove symlinks
stow -D zsh   # Remove zsh config symlinks
```

### Customizing Configs

All configs are in Stow packages and automatically symlinked to your home directory. Make changes directly in the repo - they'll be reflected immediately since they're symlinked.

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

Personal configuration repository. Fork and adapt as needed.

---
Happy coding! 🎯

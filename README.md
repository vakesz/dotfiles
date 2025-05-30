# Dotfiles

This repository contains my personal dotfiles and setup scripts for quickly configuring a new development environment on Ubuntu/Debian-based systems.

## Contents

- `.zshrc` - ZSH configuration with Oh My Zsh
- `.gitconfig` - Git configuration with useful aliases
- `.vimrc` - Vim configuration (coming soon)
- `.tmux.conf` - Tmux configuration (coming soon)
- `start.sh` - Setup script to install essential tools and applications
- `bin/` - Directory containing useful custom scripts

## Installation

Clone this repository and run the setup script:

```bash
git clone https://github.com/vakesz/dotfiles.git
cd dotfiles
chmod +x start.sh
./start.sh
```

## Features

- Oh My Zsh with carefully selected plugins for productivity
- Git configuration with 50+ time-saving aliases
- Helpful shell functions for common development tasks
- Delta for better git diffs
- Python, and other development tools setup
- Neovim configuration for modern editing

## Installed Tools

The `start.sh` script installs the following tools:

- Git - Version control
- Neovim - Modern text editor
- Python 3 with pip and venv
- Build essentials
- Zsh with Oh My Zsh
- Midnight Commander (mc)
- Delta - Better Git diff viewer
- Other developer utilities

## Custom Scripts

Several useful scripts are included in the `bin/` directory:

- `git-cleanup` - Clean up merged git branches
- `sysinfo` - Display system information

These scripts are automatically copied to `~/bin` during setup and are available in your PATH.

## Customization

Feel free to fork this repository and modify it according to your preferences. The modular structure makes it easy to add or remove components as needed.

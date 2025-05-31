# Dotfiles

Personal dotfiles and setup scripts for quickly configuring a development environment on Ubuntu/Debian-based systems.

## Contents

- `.zshrc` - ZSH configuration with Oh My Zsh
- `.gitconfig` - Git configuration with aliases
- `start.sh` - Setup script to install essential tools
- `bin/` - Custom utility scripts

## Installation

```bash
git clone https://github.com/vakesz/dotfiles.git
cd dotfiles
chmod +x start.sh
./start.sh
```

## Features

- ZSH setup with Oh My Zsh
- Git configuration with useful aliases
- Development tools installation
- Custom scripts for common tasks
- Automatic backups of existing dotfiles

## Custom Scripts

Available in `bin/` directory:
- **`git-cleanup`** - Clean up merged git branches
- **`sysinfo`** - Display system information
- **`backup-dots`** - Backup current dotfiles

## Customization

Fork and modify according to your preferences:
1. Edit package lists in `start.sh`
2. Add ZSH plugins in `.zshrc`
3. Add custom aliases in `.zshrc`
4. Create new scripts in `bin/` directory

## Backup

The setup script automatically backs up existing dotfiles. Manual backups:

```bash
backup-dots
```

Backups are stored in `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`.

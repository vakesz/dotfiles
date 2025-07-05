# Dotfiles Setup

This repository contains configuration files and a bootstrap script to quickly set up a development environment on Ubuntu/Debian systems. It includes my Git configuration, Zsh shell configuration, and a comprehensive `start.sh` setup script.

## Repository Structure

```text
.gitconfig          # Git configuration (user, color, tools, delta settings)
.zshrc              # Zsh shell configuration with Oh My Zsh and helpful aliases
.config/
  └── .p10k.zsh     # Powerlevel10k theme configuration for Zsh
start.sh            # Bootstrap script for installing packages and tools
README.md           # This documentation file
```

## Prerequisites

* Ubuntu or Debian-based distribution
* Sudo privileges (do **not** run as root)
* Internet connection

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/vakesz/dotfiles.git
   cd dotfiles
   ```

2. Make the bootstrap script executable:

   ```bash
   chmod +x start.sh
   ```

3. Run the setup script:

   ```bash
   ./start.sh
   ```

   The script will:

   * Detect the OS (`Ubuntu` or `Debian`)
   * Update and install core packages (Git, Neovim, Python, build tools, etc.)
   * Install `git-delta` for enhanced diff output
   * Install Docker Engine and add your user to the `docker` group
   * Install Node.js LTS and global npm tools (TailwindCSS, ESLint, etc.)
   * Install JetBrains Mono Nerd Font for terminal use
   * Set up Oh My Zsh with zplug plugin manager
   * Copy the provided dotfiles (`.gitconfig`, `.zshrc`, `.p10k.zsh`) to your home directory
   * Configure Zsh history rotation via cron
   * Change your default shell to Zsh
   * Apply WSL2 locale fixes if running on Windows Subsystem for Linux

4. Log out and log back in (or restart your terminal) to apply all changes.

## What Gets Installed

### Core Packages

* **Git** - Version control system
* **Neovim** - Modern terminal-based text editor
* **Python 3** - With pip and venv for package management
* **Build tools** - Essential compilation tools (gcc, clang, cmake, etc.)
* **Utilities** - htop, tree, mc, jq, unzip, and more

### Development Tools

* **Git Delta** - Enhanced diff viewer with syntax highlighting
* **Docker Engine** - Container platform with user group access
* **Node.js LTS** - JavaScript runtime with global tools:
  * TailwindCSS - Utility-first CSS framework
  * PostCSS & Autoprefixer - CSS processing tools
  * ESLint - JavaScript linter

### Shell Environment

* **Zsh** - Advanced shell with Oh My Zsh framework
* **zplug** - Plugin manager for Zsh
* **Powerlevel10k** - Feature-rich Zsh theme
* **JetBrains Mono Nerd Font** - Programming font with icon support

## Customization

* **Git**: Edit `.gitconfig` to change your user info or color schemes.
* **Zsh**: Add or remove Oh My Zsh plugins in `.zshrc`.
* **Packages**: Modify the `pkgs` array in `start.sh` to include additional packages.

---

*Happy hacking!*

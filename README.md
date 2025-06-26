# Dotfiles Setup

This repository contains configuration files and a bootstrap script to quickly set up a development environment on Ubuntu/Debian systems. It includes my Git configuration, Zsh shell configuration, and a comprehensive `start.sh` setup script.

## Repository Structure

```text
.gitconfig    # Git configuration (user, color, tools, delta settings)
.zshrc        # Zsh shell configuration with Oh My Zsh and helpful aliases
start.sh      # Bootstrap script for installing packages and tools
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
   * Update and install core packages
   * Install `git-delta` and `lazygit`
   * Install Docker Engine and add your user to the `docker` group
   * Install Node.js LTS and global npm tools
   * Install JetBrains Mono Nerd Font
   * Set up Oh My Zsh with plugins
   * Copy the provided `.gitconfig` and `.zshrc` to your home directory
   * Change your default shell to Zsh

4. Log out and log back in (or restart your terminal) to apply all changes.

## Customization

* **Git**: Edit `.gitconfig` to change your user info or color schemes.
* **Zsh**: Add or remove Oh My Zsh plugins in `.zshrc`.
* **Packages**: Modify the `pkgs` array in `start.sh` to include additional packages.

---

*Happy hacking!*

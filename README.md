# Dotfiles Setup

This repository contains configuration files and a single `install` shell script
that installs applications with [Homebrew](https://brew.sh) and links the
configs into place.

## Repository Structure

```text
git/
  .gitconfig
nvim/
  init.lua
  lua/
  KEYMAPS.md
zsh/
  .p10k.zsh
  .zshrc
install
README.md
```

## Usage

```bash
git clone https://github.com/vakesz/dotfiles.git
cd dotfiles
chmod +x install
./install
```

The script installs Homebrew if necessary, then ensures the following tools are
present and up to date: `git`, `zsh`, `neovim`, `hugo`, `rust`, `zig`,
`git-delta`, and the update helper `topgrade`. Configuration files are
symlinked into the appropriate locations under your home directory.

Run the script after setting up a new machine or periodically to keep your tools
current.

---

*Happy hacking!*

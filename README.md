<!-- filepath: /home/vakesz/git/dotfiles/README.md -->
# Dotfiles Setup

Bootstrap a productive dev environment for Ubuntu / Debian (incl. WSL2). Installs core tooling, languages, shell, font, and opinionated configs in an idempotent way.

## Features

- Single `./install` script (safe to re-run)
- Distro + WSL2 detection & small WSL fixes
- Repairs known APT key/repo issues (Neo4j, Element) if present
- Installs / updates:
  - Core CLI & build tools (git, neovim, python3/pip, gcc/clang, cmake, jq, unzip, etc.)
  - Docker Engine (+ user group)
  - Go, Zig, Node.js LTS (pnpm + tailwindcss, postcss, autoprefixer, eslint)
  - Hugo, SourceGit, Ruby gem `colorls`
  - Latest stable Neovim binary
  - JetBrains Mono Nerd Font
- Zsh environment (Oh My Zsh, zplug, Powerlevel10k, aliases, cron history rotation)
- Ships curated dotfiles: `.gitconfig`, `.zshrc`, `.p10k.zsh`, Neovim config
- Never runs fully as root; uses sudo only when needed

## Repository Layout

```text
.gitconfig
.zshrc
.config/
  ├─ .p10k.zsh
  └─ nvim/
      └─ init.lua
install          # Bootstrap script
README.md
```

## Quick Start

```bash
git clone https://github.com/vakesz/dotfiles.git
cd dotfiles
chmod +x install
./install
```

Log out / back in (or reopen terminal) so shell + group changes apply.

## Installed Stack (Summary)

- Core: git, neovim, python3(+pip, venv), build tools, utilities (htop, tree, mc, jq, unzip, etc.)
- Languages: Go, Zig, Node.js LTS (+ pnpm), Python (system), Ruby gem colorls
- Web tooling: tailwindcss, postcss, autoprefixer, eslint (global via pnpm)
- Platform: Docker Engine
- Editor: Neovim (latest stable)
- Other: Hugo, SourceGit, JetBrains Mono Nerd Font
- Shell: Zsh + Oh My Zsh + zplug + Powerlevel10k + custom aliases + history rotation

## Update

```bash
cd ~/dotfiles
git pull
./install
```

Script overwrites shipped dotfiles (backup first if diverging).

## Uninstall / Revert (Manual)

- Change shell back: `chsh -s /bin/bash`
- Remove or edit copied dotfiles
- Remove packages / runtimes via apt or their installers

## Safety

- Do not run script as root
- Review script before use in sensitive systems

## License

No explicit license. Treat as personal config; fork & adapt responsibly.

---
Happy hacking.

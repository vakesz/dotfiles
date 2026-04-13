# Dotfiles

Cross-platform dotfiles for macOS, Linux, and WSL, organized around `home/` for home-level files and `config/` for XDG-managed config.

## Quick Start

### Prerequisites

- GNU Stow
- Git

### Packages

From the repo root:

```bash
brew bundle install
```

### Bootstrap the core packages

```bash
./bootstrap.sh
```

This stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`, then asks whether to run the matching platform setup script.

### Optional machine setup

You can still run the platform setup scripts directly later:

```bash
./scripts/platform/macos.sh
./scripts/platform/linux.sh
```

### Adopt an existing setup

If your machine already has dotfiles in place and you want to import them into this repo:

```bash
./bootstrap.sh --adopt
```

`--adopt` is interactive only. It uses `stow --adopt`, which can overwrite repo files with existing local files. Review the result with `git diff`.

## Layout

```text
dotfiles/
├── assets/
│   └── macos/            # Non-stowed assets used by platform setup
├── Brewfile
├── config/               # Stowed into ~/.config
│   ├── fd/
│   ├── ghostty/
│   ├── git/
│   ├── oh-my-posh/
│   ├── ripgrep/
│   ├── tealdeer/
│   ├── topgrade.toml
│   └── zsh/
├── home/                 # Stowed into ~
│   └── .zshenv
├── scripts/
│   ├── lib/common.sh
│   └── platform/         # Optional platform setup scripts
└── bootstrap.sh
```

## Repo Model

- `./bootstrap.sh` stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`.
- Re-run `./bootstrap.sh` after adding or moving files inside `home/` or `config/`.
- Keep XDG-managed config under `config/`; keep only true home-level files in `home/`.

### Core config

- `home/.zshenv`: early shell environment such as XDG dirs and `ZDOTDIR`
- `config/zsh`: Zsh config fragments and the Oh My Posh prompt
- `config/git`: Git config and global ignore rules
- `config/ghostty`: Ghostty config
- `config/fd`, `config/ripgrep`, `config/tealdeer`, and `config/topgrade.toml`: CLI tool config

### Optional layers

- `Brewfile`: workstation and development packages for the primary macOS setup
- `scripts/platform/linux.sh`: locale and default shell setup for Linux / WSL
- `scripts/platform/macos.sh`: macOS defaults, Xcode CLT, Rosetta, custom keyboard layout, power settings, and Podman setup

## Migration Note

- `bootstrap.sh` is now the only install entrypoint
- the repo still uses `home/` plus `config/`, but the contents and naming were simplified
- the Ghostty custom icon now lives in `config/ghostty/` next to the config that references it

## Re-Stowing

Tracked files are live immediately because Stow symlinks them into place. After adding new files, re-run:

```bash
./bootstrap.sh
```

## XDG Compliance

Configs are kept out of `$HOME` where possible:

- `~/.config` for config
- `~/.local/share` for data
- `~/.local/state` for state
- `~/.cache` for cache

## Update Strategy

System and tool updates run through `topgrade`. Homebrew app auto-updates are disabled in favor of `brew upgrade --greedy-auto-updates` via topgrade.

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Oh My Posh](https://ohmyposh.dev/)
- [Zinit](https://github.com/zdharma-continuum/zinit)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)
- [topgrade](https://github.com/topgrade-rs/topgrade)

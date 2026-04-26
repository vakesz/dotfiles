# Dotfiles

macOS-primary dotfiles with Linux and WSL support, organized around `home/` for home-level files and `config/` for XDG-managed config.

## Quick Start

### 1. Install bootstrap prerequisites

`bootstrap.sh` only needs `git`, `stow`, and `zsh`. On a fresh macOS machine:

```bash
brew install git stow zsh
```

### 2. Bootstrap the dotfiles

```bash
./bootstrap.sh
```

This stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`, then asks whether to run the matching platform setup script.

### 3. Install the rest of the workstation packages (macOS)

`Brewfile` is the workstation package manifest for the primary macOS machine. It is not intended to be a cross-platform dependency source.

```bash
brew bundle install
```

### 4. Optional machine setup

You can run the platform setup scripts directly later:

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

- `Brewfile`: workstation package manifest for the primary macOS setup
- `scripts/platform/linux.sh`: locale and default shell setup for Linux / WSL
- `scripts/platform/macos.sh`: macOS defaults, Xcode CLT, Rosetta, custom keyboard layout, and power settings

## Machine-Local Customizations

Keep machine-specific overrides untracked in the paths already ignored by git:

- `config/zsh/.zshrc.local`
- `config/zsh/rc.d/*.local.zsh`
- `config/git/gitconfig.local`

These files are for local aliases, secrets, machine-specific paths, or other overrides that should not be shared.

## Install Notes

- `bootstrap.sh` is the only stow entrypoint
- re-run `./bootstrap.sh` after adding or moving tracked files inside `home/` or `config/`
- the Ghostty custom icon lives in `config/ghostty/` next to the config that references it
- shell plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) install via `Brewfile`; no separate plugin manager bootstrap is required

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
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)
- [topgrade](https://github.com/topgrade-rs/topgrade)

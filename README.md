# Dotfiles

macOS-primary dotfiles with Linux and WSL support, organized around `home/` for home-level files and `config/` for XDG-managed config.

## Quick Start

### 1. Install workstation packages (macOS)

The `Brewfile` is the package manifest for the primary macOS setup.

```bash
brew bundle install
```

### 2. Bootstrap the dotfiles

```bash
./bootstrap.sh
```

This stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`, then offers to run the matching platform setup script.
It also creates the XDG runtime directories used by the shell and prepares
`$GNUPGHOME` with private permissions.

### 3. Optional machine setup

You can run the platform setup scripts directly later:

```bash
./scripts/platform/macos.sh
./scripts/platform/linux.sh
```

Node is managed through `fnm`, not Homebrew. If `fnm` is available, the platform
setup scripts offer to install the latest Node.js LTS, select it as the `fnm`
default, and enable `pnpm` via `corepack`.

Python runtimes and installable Python CLI tools are managed through `uv`.
The shell keeps `uv`'s tool bin directory on `PATH`; Homebrew is only expected
to provide the `uv` executable itself and any non-`uv` workstation formulae.

On macOS, an extra opt-in script permanently disables Microsoft auto-updaters (EdgeUpdater + MAU) so updates flow through `topgrade` only:

```bash
./scripts/platform/macos-office-tweaks.sh
```

### 4. Adopt an existing setup

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
│   ├── ripgrep/
│   ├── starship.toml
│   ├── tealdeer/
│   ├── topgrade.toml
│   └── zsh/
├── home/                 # Stowed into ~
│   └── .zshenv
├── scripts/
│   ├── lib/common.sh
│   └── platform/         # Optional platform setup scripts
│       ├── linux.sh
│       ├── macos.sh
│       └── macos-office-tweaks.sh
└── bootstrap.sh
```

## Repo Model

- `./bootstrap.sh` stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`.
- Re-run `./bootstrap.sh` after adding or moving files inside `home/` or `config/`.
- Keep XDG-managed config under `config/` and only true home-level files in `home/`.

### Core config

- `home/.zshenv`: early shell environment such as XDG dirs and `ZDOTDIR`
- `config/zsh`: Zsh config fragments and cached tool initialization
- `config/starship.toml`: Starship prompt theme
- `config/git`: Git config and global ignore rules
- `config/ghostty`: Ghostty config
- `config/fd`, `config/ripgrep`, `config/tealdeer`, and `config/topgrade.toml`: CLI tool config

### Optional layers

- `Brewfile`: workstation package manifest for the primary macOS setup
- `scripts/platform/linux.sh`: locale and default shell setup for Linux / WSL
- `scripts/platform/macos.sh`: macOS defaults, Xcode CLT, Rosetta, custom keyboard layout, and power settings
- `scripts/platform/macos-office-tweaks.sh`: permanently disables Microsoft EdgeUpdater and Microsoft AutoUpdate (MAU) via LaunchAgent removal

## Machine-Local Customizations

Keep machine-specific overrides untracked in the paths already ignored by git:

- `config/zsh/.zshrc.local`
- `config/zsh/rc.d/*.local.zsh`
- `config/git/gitconfig.local`

These files are for local aliases, secrets, machine-specific paths, or other overrides that should not be shared.

## Install Notes

- `bootstrap.sh` is the only stow entrypoint.
- `bootstrap.sh` creates XDG config/data/state/cache/bin directories and
  initializes `$GNUPGHOME` as a `0700` directory for GnuPG.
- Shell plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) install via
  `Brewfile`; no separate plugin manager bootstrap is required.
- Short navigation aliases are kept as compatibility shims:
  `dots` changes to `~/.dotfiles`, and `c` changes to `~/Code`.
- Node runtimes are managed by `fnm`. Homebrew `node` is not declared directly; if
  it appears locally, it is a dependency of another formula and not the shell's
  preferred runtime.
- Python runtimes and global Python tools should use `uv`; `UV_TOOL_BIN_DIR`
  is on `PATH` for `uv tool install` executables.
- Homebrew Ruby is declared because zsh intentionally prefers
  `$HOMEBREW_PREFIX/opt/ruby/bin` over the macOS system Ruby. RubyGems are kept
  under `$GEM_HOME`, and `$GEM_HOME/bin` is on `PATH` for installed gem commands.
- Homebrew replacements that need explicit prefix paths are wired in zsh:
  `curl`, `sqlite`, GNU `coreutils`, GNU `make`, and Homebrew Ruby. Linked
  Homebrew tools such as `git` and `diffutils` resolve through
  `$HOMEBREW_PREFIX/bin` from `brew shellenv`.
- JavaScript formatter/linter CLIs are intentionally project-local. This repo does
  not install global `prettier`, `markdownlint-cli`, or similar npm packages.

## Re-Stowing

Stow symlinks tracked files into place, so after adding or moving files under `home/` or `config/`, just re-run `./bootstrap.sh`.

## XDG Compliance

Configs are kept out of `$HOME` where possible:

- `~/.config` for config
- `~/.local/share` for data
- `~/.local/state` for state
- `~/.cache` for cache
- `~/.local/share/gnupg` for GnuPG state and sockets

## Update Strategy

System and tool updates run through `topgrade`. Homebrew cask updates use
Topgrade's greedy cask mode so apps that normally self-update are still handled
by Homebrew. Global npm and pnpm package update steps are disabled because
JavaScript tooling is project-local.

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Starship](https://starship.rs/)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)
- [fnm](https://github.com/Schniz/fnm)
- [pnpm](https://pnpm.io/)
- [uv](https://docs.astral.sh/uv/)
- [ripgrep](https://ripgrep.dev/docs/guide/)
- [fd](https://github.com/sharkdp/fd)
- [tealdeer](https://tealdeer-rs.github.io/tealdeer/)
- [Ghostty](https://ghostty.org/docs/config)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [topgrade](https://github.com/topgrade-rs/topgrade)
- [GnuPG](https://gnupg.org/)

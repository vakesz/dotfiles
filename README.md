# Dotfiles

Cross-platform dotfiles for macOS, Linux, and WSL, organized around the XDG Base Directory specification.

## Installation

### Prerequisites

- GNU Stow
- Git

### Default install

`./install.sh` now does two things:

1. Installs the dotfiles with GNU Stow
2. Runs the matching platform setup script for macOS or Linux / WSL

The platform setup step runs after Stow succeeds. It is still interactive and asks before each optional machine change.

```bash
# macOS package install (optional)
brew bundle install

# Platform-aware install
./install.sh
```

### Migrating existing files

If your machine already has dotfiles in place and you want to import them into this repo, use the explicit adopt flow:

```bash
./install.sh --adopt
```

`--adopt` is interactive only. It uses `stow --adopt`, which can overwrite repo files with existing local files. Review the result with `git diff`.

### Re-stowing after adding files

Existing tracked files are live immediately because Stow symlinks them into place. When you add a new file to the repo, re-run:

```bash
stow -t ~/.config config
stow -t ~ home
```

## Platform Setup Scripts

### macOS

`./install.sh` starts [`scripts/platform/macos.sh`](scripts/platform/macos.sh) automatically on macOS. You can also run it directly if you want to reapply only the macOS setup steps.

- Apply Finder defaults: show extensions, path bar, icon view, folders first
- Tune keyboard, trackpad, Dock, Mission Control, screenshots
- Enable Safari developer extras
- Disable Tips notifications
- Install Xcode Command Line Tools if missing
- Configure power management (battery sleep, display sleep)
- Install the Hungarian keyboard layout from `apps/`
- Install Rosetta on Apple Silicon
- Initialize and start Podman

### Linux / WSL

`./install.sh` starts [`scripts/platform/linux.sh`](scripts/platform/linux.sh) automatically on Linux / WSL. You can also run it directly if you want to reapply only the Linux setup steps.

- Configure `en_US.UTF-8`
- Persist locale settings for supported distros
- Set `zsh` as the default shell

## What's Included

### Shell

- Zsh with XDG-compliant setup
- Oh My Posh prompt
- Zinit plugin manager
- zoxide smart `cd`
- fzf fuzzy finder

### Neovim

- lazy.nvim package manager
- LSP servers installed system-wide
- Telescope fuzzy finder
- Treesitter syntax highlighting
- Native LSP completion (nvim 0.12+) with Copilot
- conform.nvim formatting
- mini.nvim modules for statusline, surround, indentscope, and buffer removal
- Trouble diagnostics list
- which-key keybinding discovery
- fugitive and gitsigns Git integration
- Undotree undo history

See [KEYMAPS.md](KEYMAPS.md) for the current keybinding reference.

### Other

- tmux configuration
- Git config and global ignore
- fd config
- ripgrep config
- tealdeer config
- Ghostty config
- topgrade config

## Structure

```text
dotfiles/
├── home/                  # stow -t ~
│   └── .zshenv            # Sets XDG dirs and ZDOTDIR
├── config/                # stow -t ~/.config
│   ├── fd/
│   ├── ghostty/
│   ├── git/
│   ├── nvim/
│   ├── oh-my-posh/
│   ├── ripgrep/
│   ├── tealdeer/
│   ├── tmux/
│   ├── topgrade.toml
│   └── zsh/
│       ├── .zprofile
│       ├── .zshrc
│       └── rc.d/          # Ordered shell config fragments
├── scripts/
│   ├── lib/
│   │   └── common.sh      # Shared shell helpers
│   └── platform/
│       ├── linux.sh       # Optional Linux / WSL machine setup
│       └── macos.sh       # Optional macOS machine setup
├── apps/                  # Non-stowed assets
├── Brewfile               # Homebrew packages
└── install.sh             # Platform setup + Stow bootstrap
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

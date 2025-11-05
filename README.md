# Dotfiles

Cross-platform dotfiles for macOS, Linux, and WSL. Managed with [GNU Stow](https://www.gnu.org/software/stow/) and automated setup scripts.

## Features

- **Cross-platform**: Works on macOS, Linux, and WSL
- **XDG Base Directory compliant**: Clean home directory
- **Automated installation**: Single command setup
- **Platform-specific configurations**: Optimized for each OS
- **Version controlled**: Track and sync across machines

## What's Included

### Shell Configuration

- **Zsh** with XDG-compliant setup
- **Oh My Posh** for cross-platform prompts
- **Zinit** for plugin management
- Platform-specific PATH and environment variables

### Package Management

- `packages.json` - Unified package mapping for all platforms
- Automatic package installation via brew/apt/cargo/pip/npm
- Platform-specific package resolution

## Directory Structure

```txt
~/dotfiles/
├── .config/              # Application configurations
│   ├── git/             # Git config
│   ├── nvim/            # Neovim config
│   ├── oh-my-posh/      # Prompt theme
│   ├── tmux/            # Terminal multiplexer
│   └── zsh/             # Zsh configuration
├── scripts/             # Installation and setup scripts
│   ├── packages.json    # Cross-platform package mapping (main source)
│   ├── mac.sh          # macOS-specific setup
│   └── wsl.sh          # WSL-specific setup
├── .gitconfig          # Global git configuration
├── .stow-local-ignore  # Stow ignore patterns
├── .zshenv             # Zsh environment (XDG setup)
├── install.sh          # Main installation script
└── README.md           # This file
```

## XDG Base Directory

This setup follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

- `XDG_CONFIG_HOME`: `~/.config` - User-specific configurations
- `XDG_DATA_HOME`: `~/.local/share` - User-specific data files
- `XDG_STATE_HOME`: `~/.local/state` - User-specific state data
- `XDG_CACHE_HOME`: `~/.cache` - User-specific cache files

The `.zshenv` file sets `ZDOTDIR` to `~/.config/zsh`, keeping zsh configs out of `$HOME`.

## Customization

### Adding Packages

All packages are managed in `scripts/packages.json`. Add entries like this:

```json
{
  "name": "package-name",
  "brew": "package-name",
  "apt": "package-name",
  "cargo": "package-name",
  "pip": "package-name",
  "npm": "package-name",
  "manual": "curl -s https://example.com/install.sh | bash",
  "description": "What this package does"
}
```

## Troubleshooting

### Stow conflicts

If stow reports conflicts:

1. Backup the conflicting files
2. Remove or rename them
3. Run `stow .` again

The install script automatically backs up existing files to `~/.dotfiles_backup_<timestamp>/`.

### Missing commands on Linux

Some tools need manual installation:

```bash
# oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s

# Rust (for zoxide, etc.)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Then install tools
cargo install zoxide
```

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Oh My Posh](https://ohmyposh.dev/)
- [Zinit](https://github.com/zdharma-continuum/zinit)

# Dotfiles

This repository contains my personal dotfiles and setup scripts for quickly configuring a new development environment on Ubuntu/Debian-based systems.

## Contents

- `.zshrc` - ZSH configuration with Oh My Zsh and performance optimizations
- `.gitconfig` - Git configuration with useful aliases and Delta integration
- `.vimrc` - Vim configuration (coming soon)
- `.tmux.conf` - Tmux configuration (coming soon)
- `start.sh` - Setup script to install essential tools and applications
- `bin/` - Directory containing useful custom scripts

## Installation

Clone this repository and run the setup script:

```bash
git clone https://github.com/vakesz/dotfiles.git
cd dotfiles
chmod +x start.sh
./start.sh
```

## Features

- **Modern ZSH setup** with Oh My Zsh and performance-optimized plugins
- **Git configuration** with 50+ time-saving aliases and Delta for better diffs
- **Docker integration** with helpful aliases and cleanup functions
- **Development tools** including Node.js, Python, and build essentials
- **Custom scripts** for project initialization, system info, and maintenance
- **FZF integration** for fuzzy finding files and history
- **Automatic backups** of existing dotfiles before installation

## Installed Tools

The `start.sh` script installs:

### Essential Development Tools
- Git with Delta for enhanced diffs
- Neovim for modern text editing
- Python 3 with pip and virtual environments
- Node.js (LTS) with npm
- Docker and Docker Compose
- Build essentials (gcc, make, cmake, clang, gdb)

### Modern CLI Tools
- **ripgrep** (`rg`) - Fast text search
- **fd** - Fast file finder
- **bat** - Better `cat` with syntax highlighting
- **fzf** - Fuzzy finder for files and command history
- **jq** - JSON processor

### Shell and Productivity
- Zsh with Oh My Zsh framework
- Multiple ZSH plugins for autocompletion and syntax highlighting
- Midnight Commander for file management
- htop for system monitoring

## Custom Scripts

### Available in `bin/` directory:

- **`git-cleanup`** - Clean up merged git branches safely
- **`sysinfo`** - Display comprehensive system information
- **`project-init`** - Initialize new projects (Python, Node.js) with proper structure
- **`backup-dots`** - Backup current dotfiles before making changes

Scripts are automatically copied to `~/bin` and added to PATH during setup.

## ZSH Features

### Aliases
- Modern tool alternatives (`cat` → `bat`, `find` → `fd`, `grep` → `rg`)
- Docker shortcuts (`dps`, `dex`, `dlog`, etc.)
- Git shortcuts beyond `.gitconfig` aliases
- Development helpers (`py`, `serve`, `json`)

### Functions
- **`docker-cleanup`** - Remove unused Docker resources
- **`docker-size`** - Show Docker disk usage
- **`extract`** - Extract various archive formats
- **`hash_file`** - Generate multiple hash types for files
- **`myports`** - Show listening ports
- **`port <number>`** - Show what's using a specific port

## Troubleshooting

### Common Issues

**ZSH plugins not working:**
```bash
# Reload ZSH configuration
source ~/.zshrc
# Or restart your terminal
```

**Docker permission denied:**
```bash
# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

**Git Delta not showing colors:**
```bash
# Ensure your terminal supports 256 colors
echo $TERM
# Should show something like 'xterm-256color'
```

**Locale warnings:**
```bash
# Generate missing locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
```

**FZF not working:**
```bash
# Install FZF key bindings
$(brew --prefix)/opt/fzf/install  # macOS
/usr/share/doc/fzf/examples/key-bindings.zsh  # Linux
```

### Performance Issues

If ZSH feels slow:
1. Comment out plugins in `.zshrc` one by one to identify the culprit
2. Use `fast-syntax-highlighting` instead of `zsh-syntax-highlighting`
3. Check `zsh-bench` for startup time analysis

### WSL2 Specific

**Git safe directory warnings:**
```bash
git config --global --add safe.directory '*'
```

**SSH agent in WSL:**
The setup automatically configures SSH agent startup in WSL environments.

## Customization

Feel free to fork this repository and modify it according to your preferences. The modular structure makes it easy to add or remove components:

1. **Add new packages**: Edit the `apt install` section in `start.sh`
2. **Add ZSH plugins**: Add to the `plugins` array in `.zshrc`
3. **Add custom aliases**: Add to the aliases section in `.zshrc`
4. **Add new scripts**: Create executable files in the `bin/` directory

## Backup and Recovery

The setup script automatically creates backups of existing dotfiles before installation. Manual backups can be created using:

```bash
backup-dots
```

Backups are stored in `~/.dotfiles_backup_YYYYMMDD_HHMMSS/` with timestamps.

## Contributing

Suggestions and improvements are welcome! Please open an issue or submit a pull request.

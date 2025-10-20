# Brewfile for dotfiles setup
# Install with: brew bundle

# ============================================================================
# Core Development Tools
# ============================================================================
brew "git"
brew "git-delta"           # Better git diff viewer
brew "curl"
brew "wget"
brew "jq"
brew "tree-sitter"         # Parser generator for syntax highlighting

# ============================================================================
# Shell and Terminal Tools
# ============================================================================
brew "zsh"
brew "starship"            # Cross-shell prompt
brew "zsh-autosuggestions"
brew "zsh-fast-syntax-highlighting"
brew "zsh-completions"
brew "tmux"
brew "fzf"                 # Fuzzy finder
brew "ripgrep"             # Fast grep alternative
brew "fd"                  # Fast find alternative
brew "lsd"                 # Modern ls
brew "bat"                 # Cat with syntax highlighting
brew "tldr"                # Simplified man pages
brew "tig"                 # Text-mode interface for git
brew "httpie"              # HTTP client
brew "nmap"                # Network mapper
brew "zoxide"              # Smart cd command

# ============================================================================
# Text Editors and IDE Tools
# ============================================================================
brew "neovim"
brew "shellcheck"          # Shell script analyzer

# ============================================================================
# Programming Languages and Runtimes
# ============================================================================
brew "go"
brew "python"
brew "rust"
brew "zig"
brew "lua"
brew "ruby"
brew "node@22"
brew "deno"                # TypeScript/JavaScript runtime (for peek.nvim)

# ============================================================================
# Language-Specific Package Managers
# ============================================================================
brew "pnpm"                # Fast npm alternative
brew "pipx"                # Install Python apps in isolated environments

# ============================================================================
# Build Tools and Compilers
# ============================================================================
brew "cmake"
brew "make"
brew "ninja"
brew "pkg-config"
brew "autoconf"
brew "automake"
brew "gcc"
brew "llvm"

# ============================================================================
# Code Formatters and Linters
# ============================================================================
brew "stylua"              # Lua formatter
brew "prettier"            # JavaScript/TypeScript/JSON/YAML/Markdown formatter
brew "clang-format"        # C/C++/Objective-C formatter
brew "black"               # Python formatter (backup - ruff_format is preferred)
brew "ruff"                # Fast Python linter and formatter

# ============================================================================
# Testing Tools
# ============================================================================
brew "pytest"              # Python testing framework

# ============================================================================
# Debuggers and Analyzers
# ============================================================================
brew "gdb"                 # GNU debugger
brew "cppcheck"            # C/C++ static analyzer

# ============================================================================
# Container and Deployment Tools
# ============================================================================
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "colima"              # Container runtime for macOS/Linux

# ============================================================================
# iOS Development Tools (macOS only)
# ============================================================================
brew "xcodegen" if OS.mac?
brew "swiftlint" if OS.mac?           # Swift linter
brew "swiftformat" if OS.mac?         # Swift formatter
brew "xcbeautify" if OS.mac?          # Beautify xcodebuild output
brew "xcinfo" if OS.mac?              # Simulator management

# ============================================================================
# Additional Utilities
# ============================================================================
brew "mc"                  # Midnight Commander
brew "hugo"                # Static site generator
brew "fontconfig"
brew "pre-commit"          # Git pre-commit hook framework
brew "topgrade"            # Update everything

# ============================================================================
# macOS Applications
# ============================================================================
cask "font-jetbrains-mono-nerd-font" if OS.mac?
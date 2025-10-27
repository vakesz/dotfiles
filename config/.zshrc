# ============================================================================
# Zsh Configuration
# ============================================================================
# Exit if not running interactively
[[ $- != *i* ]] && return

# ============================================================================
# XDG Base Directories
# ============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ============================================================================
# Locale Configuration
# ============================================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# ============================================================================
# Helper Functions
# ============================================================================
have() { command -v "$1" >/dev/null 2>&1; }
alias_if_exists() { have "$2" && alias "$1"="$3"; }

# Add Homebrew keg-only package to PATH
add_keg_only() {
    local pkg="$1"
    local bin_path="${2:-bin}"  # Default to 'bin', allow override like 'libexec/gnubin'

    if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/$pkg/$bin_path" ]]; then
        export PATH="$HOMEBREW_PREFIX/opt/$pkg/$bin_path:$PATH"

        # Add build flags if library directories exist
        if [[ -d "$HOMEBREW_PREFIX/opt/$pkg/lib" ]]; then
            export LDFLAGS="-L$HOMEBREW_PREFIX/opt/$pkg/lib${LDFLAGS:+ $LDFLAGS}"
        fi
        if [[ -d "$HOMEBREW_PREFIX/opt/$pkg/include" ]]; then
            export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/$pkg/include${CPPFLAGS:+ $CPPFLAGS}"
        fi
        if [[ -d "$HOMEBREW_PREFIX/opt/$pkg/lib/pkgconfig" ]]; then
            export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/$pkg/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
        fi
    fi
}

# ============================================================================
# History Configuration
# ============================================================================
mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

# ============================================================================
# Homebrew Setup (Cross-Platform)
# ============================================================================
if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d ~/.linuxbrew ]]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
fi

# ============================================================================
# Zsh Options for Better UX
# ============================================================================
setopt AUTO_CD               # Auto cd to directories
setopt GLOB_DOTS             # Include hidden files in glob
setopt NO_BEEP               # No annoying beep
setopt PROMPT_SUBST          # Enable prompt substitution
setopt AUTO_PUSHD            # Push directories onto the stack
setopt PUSHD_IGNORE_DUPS     # Don't push duplicate directories
setopt PUSHD_SILENT          # Don't print the directory stack

# ============================================================================
# PATH Configuration
# ============================================================================

# Homebrew keg-only packages
add_keg_only "node@22"
add_keg_only "ruby"
add_keg_only "make" "libexec/gnubin"
add_keg_only "python@3.13"
add_keg_only "llvm"

# NPM/PNPM/Yarn - Keep global installs in XDG directory
export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# Go
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# Language Runtime Paths
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export PATH="$CARGO_HOME/bin:$PATH"

export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/pipx/venvs/bin:$PATH"

# Deno
export DENO_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# ============================================================================
# Aliases
# ============================================================================

# Modern ls replacement (lsd)
if have lsd; then
    alias ls='lsd'
    alias ll='lsd -lah'
    alias la='lsd -A'
    alias lt='lsd --tree --depth 2'
    alias l='lsd -lh'
else
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -lh'
fi

# Modern cat replacement (bat)
if have bat; then
    alias cat='bat --paging=never --style=plain'
    alias ccat='bat --paging=never'  # cat with colors
    alias less='bat'
fi

# Directory Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Zoxide - smart directory jumping (replaces cd)
if have zoxide; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# Git Aliases
alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gf='git fetch'

# ============================================================================
# Custom Functions
# ============================================================================

# Python virtual environment helper
alias python='python3.13'
alias python3='python3.13'
alias pip='pip3.13'
alias pip3='pip3.13'
alias py='python3.13'

# Quick virtual environment activation
venv() {
    [ -d .venv ] || py -m venv .venv
    source .venv/bin/activate
}

# ============================================================================
# Zsh Plugins
# ============================================================================
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    if [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi

    # Syntax highlighting (load after autosuggestions)
    if [[ -f "$HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
        source "$HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
    fi

    # Additional completions
    if [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]]; then
        FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
    fi
fi

# ============================================================================
# Completions Setup
# ============================================================================
autoload -Uz compinit

# Only regenerate compdump once a day for faster startup
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Completion styling
setopt AUTO_LIST              # Automatically list choices on ambiguous completion
setopt AUTO_MENU              # Use menu completion after second tab press
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt ALWAYS_TO_END          # Move cursor to end if word had one match

# Better completion matching (case-insensitive, partial matching)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

# Cache completions for faster loading
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# ============================================================================
# Tool Integrations & Configurations
# ============================================================================

# fzf (Fuzzy Finder)
if have fzf; then
    eval "$(fzf --zsh)"

    if have bat; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
    fi

    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"

    if have fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# Git Delta (Better git diff)
if have delta; then
    export GIT_PAGER='delta'
fi

# Ripgrep
if have rg; then
    # Use ripgrep config file if it exists
    export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
fi

# Neovim (default editor)
if have nvim; then
    alias vi='nvim'
    alias vim='nvim'
    export EDITOR='nvim'
    export VISUAL='nvim'
    export MANPAGER='nvim +Man!'  # Use nvim as man pager
fi

# Less/Pager
export LESS='-R -F -X -i'  # Raw color codes, quit if one screen, no init, case-insensitive search
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# Python XDG compliance
export PYTHONSTARTUP="${XDG_CONFIG_HOME:-$HOME/.config}/python/pythonrc"
export PYTHON_HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/python/history"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-$HOME/.cache}/python"
export PYTHONUSERBASE="${XDG_DATA_HOME:-$HOME/.local/share}/python"

# pip XDG compliance
export PIP_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pip/pip.conf"
export PIP_LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pip/log"

# Starship Prompt
if have starship; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
fi

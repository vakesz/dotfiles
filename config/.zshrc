# oh, hello there!

# --- Shell interactivity check ------------------------------------------------
[[ $- != *i* ]] && return

# --- XDG base directories -----------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- Locale -------------------------------------------------------------------
# Avoid assorted locale warnings
export LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" LANGUAGE="en_US.UTF-8" LC_CTYPE="en_US.UTF-8"

# --- Utilities (helpers) ------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }
alias_if_exists() { have "$2" && alias "$1"="$3"; }

# --- History ------------------------------------------------------------------
mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history" HISTSIZE=50000 SAVEHIST=50000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS \
       HIST_IGNORE_SPACE HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
HIST_STAMPS="yyyy-mm-dd"
COMPLETION_WAITING_DOTS=true

# --- Path Setup ---------------------------------------------------------------
if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d ~/.linuxbrew ]]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
fi
# --- Lazy Loading for Slow Commands ------------------------------------------
# Only load nvm when needed
nvm() {
    unset -f nvm
    export NVM_DIR="$HOME/.config/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}

# --- Zsh Options for Better UX -----------------------------------------------
setopt AUTO_CD              # Auto cd to directories
setopt CORRECT              # Correct commands
setopt GLOB_DOTS            # Include hidden files in glob
setopt NO_BEEP              # No annoying beep
setopt PROMPT_SUBST         # Enable prompt substitution

# --- General Aliases ---------------------------------------------------------
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# --- Aliases: python & tooling ------------------------------------------------
alias py='python3'
alias pip='pip3'
venv() {
  [ -d .venv ] || python3 -m venv .venv
  # shellcheck disable=SC1091
  source .venv/bin/activate
}

# --- System Info -------------------------------------------------------------
alias myip='curl -s https://ipinfo.io/ip'
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias pscpu='ps auxf | sort -nr -k 3'
alias psmem='ps auxf | sort -nr -k 4'

# --- Enhanced Functions ------------------------------------------------------
# Quick note taking
note() {
    local note_dir="$HOME/notes"
    mkdir -p "$note_dir"
    ${EDITOR:-vim} "$note_dir/$(date +%Y-%m-%d).md"
}

# Find and kill process by name
killp() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Create a backup of a file/directory
backup() {
    cp -r "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Weather function
weather() {
    curl -s "wttr.in/${1:-}" | head -n 17
}

# Disk usage of current directory
duh() {
    du -sh * | sort -hr
}

# --- macOS Specific ----------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Homebrew completions
    if type brew &>/dev/null; then
        FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
    fi
    
    # Quick Look alias
    alias ql='qlmanage -p'
    
    # Show/hide hidden files in Finder
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
fi

# --- Starship Prompt ---------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
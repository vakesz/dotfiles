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
# --- Zsh Options for Better UX -----------------------------------------------
setopt AUTO_CD              # Auto cd to directories
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

# --- Node.js (Homebrew keg-only) ---------------------------------------------
# Put Node 22 first in PATH so `node`, `npm`, `npx`, `corepack` resolve.
if [[ -x /opt/homebrew/opt/node@22/bin/node ]]; then
  export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
  # Helpful when building native addons
  export LDFLAGS="-L/opt/homebrew/opt/node@22/lib${LDFLAGS:+:$LDFLAGS}"
  export CPPFLAGS="-I/opt/homebrew/opt/node@22/include${CPPFLAGS:+:$CPPFLAGS}"
fi

# Keep npm/pnpm/yarn global installs in XDG dir (no /usr/local pollution)
export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# Enable Corepack to manage Yarn/Pnpm that ship with Node
have corepack && corepack enable --install-directory "$NPM_CONFIG_PREFIX/bin"

# --- Starship Prompt ---------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"

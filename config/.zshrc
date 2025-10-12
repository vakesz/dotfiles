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
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/node@22/bin/node" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/node@22/bin:$PATH"
  # Helpful when building native addons
  export LDFLAGS="-L$HOMEBREW_PREFIX/opt/node@22/lib${LDFLAGS:+ $LDFLAGS}"
  export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/node@22/include${CPPFLAGS:+ $CPPFLAGS}"
fi

# --- Ruby (Homebrew keg-only) ------------------------------------------------
# Put Homebrew Ruby first in PATH so `ruby`, `gem`, `bundle`, etc. resolve.
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/ruby/bin/ruby" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
  # Helpful when building gems with native extensions
  export LDFLAGS="-L$HOMEBREW_PREFIX/opt/ruby/lib${LDFLAGS:+ $LDFLAGS}"
  export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/ruby/include${CPPFLAGS:+ $CPPFLAGS}"
  export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/ruby/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi

# --- Make (Homebrew keg-only) ------------------------------------------------
# Put Homebrew Make first in PATH so `make`, `gmake` resolve.
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/make/libexec/gnubin/make" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/make/libexec/gnubin:$PATH"
fi

# Keep npm/pnpm/yarn global installs in XDG dir (no /usr/local pollution)
export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# Enable Corepack to manage Yarn/Pnpm that ship with Node
have corepack && corepack enable --install-directory "$NPM_CONFIG_PREFIX/bin"

# --- Zsh Plugins (Homebrew) --------------------------------------------------
# Command autosuggestions from history (like Fish)
if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting (must be loaded after autosuggestions)
if [[ -f /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
    source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

# Additional completions
if [[ -d /opt/homebrew/share/zsh-completions ]]; then
    FPATH="/opt/homebrew/share/zsh-completions:$FPATH"
fi

# --- Completions Setup -------------------------------------------------------
autoload -Uz compinit
# Only regenerate compdump once a day for faster startup
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Completion options for better UX
setopt AUTO_LIST              # Automatically list choices on ambiguous completion
setopt AUTO_MENU              # Use menu completion after second tab press
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt ALWAYS_TO_END          # Move cursor to end if word had one match

# Better completion matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

# --- Key Bindings ------------------------------------------------------------
# Emacs-style bindings (Ctrl+A/E for line start/end, etc.)
bindkey -e

# Better word navigation
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[3~' delete-char         # Delete key
bindkey '^[[H' beginning-of-line    # Home key
bindkey '^[[F' end-of-line          # End key

# --- Starship Prompt ---------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
export THEOS=~/theos

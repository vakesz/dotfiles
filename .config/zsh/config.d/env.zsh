# ============================================================================
# Environment Variables
# ============================================================================
# All environment variable exports (non-PATH)

# ----------------------------------------------------------------------------
# Locale
# ----------------------------------------------------------------------------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# ----------------------------------------------------------------------------
# Editor
# ----------------------------------------------------------------------------
if have nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  export MANPAGER='nvim +Man!'
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

# ----------------------------------------------------------------------------
# GPG
# ----------------------------------------------------------------------------
if [[ -n "$TTY" ]]; then
  export GPG_TTY=$(tty)
else
  export GPG_TTY="$TTY"
fi

# ----------------------------------------------------------------------------
# Development Tools
# ----------------------------------------------------------------------------

# Less: Better default options
export LESS='-R -i -M -W -x4 -F -X'
export LESSHISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/less/history"

# Ripgrep config
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/config"

# FZF default options
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --color=fg:-1,bg:-1,hl:#5f87af
  --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff
  --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
  --color=marker:#87ff00,spinner:#af5fff,header:#87afaf
'

# BAT (cat with syntax highlighting)
export BAT_THEME="TwoDark"
export BAT_STYLE="numbers,changes,header"

# ----------------------------------------------------------------------------
# History
# ----------------------------------------------------------------------------
export HISTSIZE=10000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
export HISTDUP=erase

# ----------------------------------------------------------------------------
# Compilation Flags
# ----------------------------------------------------------------------------
# Set architecture flags for compilation (mainly for macOS M1/M2)
if [[ "$OS_TYPE" == "macos" ]]; then
  export ARCHFLAGS="-arch $(uname -m)"
fi

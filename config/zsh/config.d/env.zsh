# Environment Variables

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

if have nvim; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  export MANPAGER='nvim +Man!'
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

if [[ -t 0 ]]; then
  export GPG_TTY=$TTY
fi

# XDG paths for tools
export LESS='-R -i -M -W -x4 -F'
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"
export CURL_HOME="${XDG_CONFIG_HOME}/curl"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
export MIX_XDG=1
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"
export NODE_REPL_HISTORY="${XDG_STATE_HOME}/node_repl_history"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}/bundle"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GCM_CREDENTIAL_CACHE_DIR="${XDG_CACHE_HOME}/git-credential-manager"
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME}/tealdeer"

export XDG_BIN_HOME="${XDG_BIN_HOME:-$XDG_DATA_HOME/bin}"
export PATH="$XDG_BIN_HOME:$PATH"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --color=fg:#737aa2,bg:-1,hl:#7dcfff
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#e0af68,prompt:#f7768e,pointer:#bb9af7
  --color=marker:#7dcfff,spinner:#bb9af7,header:#565f89
'

# Shell options
unsetopt FLOW_CONTROL         # Disable flow control (Ctrl-S/Ctrl-Q)
setopt AUTO_CD                # Type directory name to cd into it
setopt AUTO_PUSHD             # Push old directory onto stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates
setopt PUSHD_SILENT           # Don't print stack after pushd/popd
setopt EXTENDED_GLOB          # Extended glob patterns (#, ~, ^)
setopt GLOB_DOTS              # Include dotfiles in globs
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell

# History
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries from history
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from history items
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt SHARE_HISTORY          # Share history between all sessions (implies INC_APPEND_HISTORY)
setopt HIST_VERIFY            # Show expanded history command before executing

# History search with arrow keys
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # Up arrow
bindkey '^[[B' down-line-or-beginning-search  # Down arrow

if [[ "$OS_TYPE" == "macos" ]]; then
  export ARCHFLAGS="-arch $CPUTYPE"
fi

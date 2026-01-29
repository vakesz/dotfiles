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
  GPG_TTY=$(tty)
  export GPG_TTY
fi

# XDG paths for tools
export LESS='-R -i -M -W -x4 -F -X'
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
  --color=fg:-1,bg:-1,hl:#5f87af
  --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff
  --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
  --color=marker:#87ff00,spinner:#af5fff,header:#87afaf
'

# History
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME}/zsh/history"

if [[ "$OS_TYPE" == "macos" ]]; then
  ARCHFLAGS="-arch $(uname -m)"
  export ARCHFLAGS
fi

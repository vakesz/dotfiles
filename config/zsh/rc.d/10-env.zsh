# Environment, helpers, and shell behavior

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

typeset -U path

case "$OSTYPE" in
  darwin*)
    export OS_TYPE="macos"
    ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      export OS_TYPE="wsl"
    else
      export OS_TYPE="linux"
    fi
    ;;
  *)
    export OS_TYPE="unknown"
    ;;
esac

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

cache_tool_init() {
  local executable_path="$1" cache_file="$2" init_command="$3" config_file="${4:-}"

  [[ -x "$executable_path" ]] || return 1

  if [[ ! -f "$cache_file" || "$executable_path" -nt "$cache_file" || ( -n "$config_file" && "$config_file" -nt "$cache_file" ) ]]; then
    mkdir -p "${cache_file:h}"
    eval "$init_command" > "$cache_file" 2>/dev/null
  fi

  source "$cache_file"
}

load_tool_init() {
  local tool_name="$1" init_command="$2" config_file="${3:-}" executable_path=""

  command_exists "$tool_name" || return 0
  executable_path="$(command -v "$tool_name")" || return 0

  cache_tool_init "$executable_path" "$XDG_CACHE_HOME/zsh/${tool_name}-init.zsh" "$init_command" "$config_file"
}

export LANG="en_US.UTF-8"
export COLORTERM="truecolor"

export EDITOR="vi"
export VISUAL="vi"

if [[ -t 0 ]]; then
  export GPG_TTY="$TTY"
fi

export LESS='-R -i -M -W -x4 -F'
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"
export NODE_REPL_HISTORY="${XDG_STATE_HOME}/node_repl_history"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GCM_CREDENTIAL_CACHE_DIR="${XDG_CACHE_HOME}/git-credential-manager"
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME}/tealdeer"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

unsetopt FLOW_CONTROL
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt INTERACTIVE_COMMENTS

export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

if [[ "$OS_TYPE" == "macos" ]]; then
  export ARCHFLAGS="-arch $CPUTYPE"
fi

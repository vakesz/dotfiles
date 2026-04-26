# Environment, helpers, and shell behavior

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

cached_eval() {
  # Source `init_command` output via $cache_file; regen if cache is missing or any dep is newer.
  local cache_file="$1" init_command="$2"; shift 2
  local dep regen=0

  [[ -f "$cache_file" ]] || regen=1
  for dep in "$@"; do
    [[ "$dep" -nt "$cache_file" ]] && { regen=1; break; }
  done

  if (( regen )); then
    mkdir -p "${cache_file:h}"
    eval "$init_command" > "$cache_file" 2>/dev/null
  fi

  source "$cache_file"
}

load_tool_init() {
  local tool="$1" init_command="$2"; shift 2
  local exe
  exe="$(command -v "$tool")" || return 0
  cached_eval "$XDG_CACHE_HOME/zsh/${tool}-init.zsh" "$init_command" "$exe" "$@"
}

export LANG="en_US.UTF-8"
export COLORTERM="truecolor"

export EDITOR="vi"
export VISUAL="vi"

[[ -t 0 ]] && export GPG_TTY="$TTY"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

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
export HISTFILE="$XDG_STATE_HOME/zsh/history"
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

[[ "$OS_TYPE" == "macos" ]] && export ARCHFLAGS="-arch $CPUTYPE"

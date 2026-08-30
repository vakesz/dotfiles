# Environment, helpers, and shell behavior

typeset -U path

typeset -g OS_TYPE="unknown"
case "$OSTYPE" in
  darwin*) OS_TYPE="macos" ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS_TYPE="wsl"
    else
      OS_TYPE="linux"
    fi
    ;;
esac

compile_zsh_file_if_stale() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  [[ ! -f "${file}.zwc" || "$file" -nt "${file}.zwc" ]] && zcompile -R "$file" 2>/dev/null
  return 0
}

source_cached_init() {
  local cache_file="$1" init_command="$2"; shift 2
  local dep refresh=0 tmp_file

  [[ -s "$cache_file" ]] || refresh=1
  for dep in "$@"; do
    [[ -e "$dep" && "$dep" -nt "$cache_file" ]] && { refresh=1; break; }
  done

  if (( refresh )); then
    mkdir -p "${cache_file:h}"
    tmp_file="${cache_file}.$$"
    if eval "$init_command" > "$tmp_file" 2>/dev/null; then
      mv "$tmp_file" "$cache_file"
    else
      rm -f "$tmp_file"
      return 0
    fi
  fi

  compile_zsh_file_if_stale "$cache_file"
  source "$cache_file"
}

load_cached_tool_init() {
  local tool="$1" init_command="$2"; shift 2
  (( $+commands[$tool] )) || return 0
  source_cached_init "$XDG_CACHE_HOME/zsh/${tool}-init.zsh" "$init_command" "$commands[$tool]" "$@"
}

# Measure interactive startup time, averaged over N login shells (default 10).
zsh-profile() {
  local runs="${1:-10}" i
  for (( i = 1; i <= runs; i++ )); do
    /usr/bin/time zsh -lic exit
  done
}

export LANG="en_US.UTF-8"
export COLORTERM="truecolor"

export EDITOR="vi"
export VISUAL="vi"

[[ -t 0 ]] && export GPG_TTY="$TTY"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

# Vi keybindings, stated explicitly. zsh was already landing on this keymap, but
# only as a side effect of $EDITOR above containing "vi" — so the mode silently
# depended on an unrelated setting. Declaring it keeps the two independent.
#
# This has to happen here rather than in 70-keybindings.zsh: fzf's init in
# 30-tools.zsh binds Tab into whichever keymap is current at the time, so
# switching keymaps afterwards would drop fzf completion.
bindkey -v

# zsh waits KEYTIMEOUT hundredths of a second after ESC to see whether an escape
# sequence follows. The default 40 puts a 0.4s stall on every insert-to-normal
# switch. 1 makes the mode change feel immediate; the cost is that a terminal
# delivering an arrow-key sequence in pieces can be misread as bare ESC, which
# only shows up over a laggy remote session.
KEYTIMEOUT=1

unsetopt FLOW_CONTROL
unsetopt BEEP
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS

# Treat / and - as word boundaries so word-wise editing stops at path/flag parts.
WORDCHARS="${WORDCHARS//[\/-]/}"

# HISTSIZE is deliberately larger than SAVEHIST: HIST_EXPIRE_DUPS_FIRST can
# only drop duplicates ahead of unique entries if the in-memory list has slack.
HISTSIZE=120000
SAVEHIST=100000
HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "${HISTFILE:h}"   # Guarantee the dir for non-login shells that skip .zprofile.
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY       # Record timestamp and duration for each command.
setopt HIST_EXPIRE_DUPS_FIRST # Trim duplicates before unique entries when full.
setopt HIST_SAVE_NO_DUPS      # Never write a duplicate to the history file.
setopt HIST_NO_STORE          # Keep `history` and `fc` calls out of history.
# SHARE_HISTORY has every terminal writing to one file; fcntl locking is the
# only mode that is safe when several of them flush at once.
setopt HIST_FCNTL_LOCK

# Print a timing breakdown for anything that runs longer than this many seconds.
REPORTTIME=10

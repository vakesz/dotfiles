# Only run Powerlevel10k instant prompt in zsh
if [[ -n $ZSH_VERSION ]]; then
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# =============================== Shell interactivity check ===============================
[[ $- != *i* ]] && return

# =============================== XDG base directories ===============================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# =============================== zplug plugin manager ===============================
export ZPLUG_HOME="${ZPLUG_HOME:-$HOME/.zplug}"
source "$ZPLUG_HOME/init.zsh"

# Self-update zplug weekly in background
zplug "zplug/zplug", hook-build:'zplug --self-manage', from:github

# =============================== Theme ===============================
zplug "romkatv/powerlevel10k", as:theme, depth:1

# =============================== Oh-My-Zsh core plugins ===============================
zplug "plugins/git",                   from:oh-my-zsh, as:plugin, defer:2
zplug "plugins/history",               from:oh-my-zsh, as:plugin, defer:2
zplug "plugins/colored-man-pages",     from:oh-my-zsh, as:plugin, defer:3
zplug "plugins/command-not-found",     from:oh-my-zsh, as:plugin, defer:3
zplug "plugins/python",                from:oh-my-zsh, as:plugin, defer:2

# =============================== Community plugins ===============================
zplug "mafredri/zsh-async",                         defer:2
zplug "zsh-users/zsh-autosuggestions",              defer:3
zplug "zsh-users/zsh-completions",                  defer:3
zplug "zdharma-continuum/fast-syntax-highlighting", defer:3

# =============================== Install & load plugins ===============================
if ! zplug check; then
  echo "→ Installing missing zplug plugins…"
  zplug install
fi
zplug load

# =============================== Completion & prompt init ===============================
mkdir -p "$XDG_CACHE_HOME/zsh"  # ensure cache dir exists

autoload -Uz compinit promptinit
compinit -d "$XDG_CACHE_HOME/zsh/compdump" -C  # use cached completions
promptinit

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh"

# =============================== Locale ===============================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# =============================== History ===============================
mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

setopt APPEND_HISTORY             # add commands to history immediately
setopt INC_APPEND_HISTORY         # ...even from other sessions
setopt SHARE_HISTORY              # share across shells
setopt EXTENDED_HISTORY           # log duration + timestamp

setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS \
       HIST_IGNORE_SPACE HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
HIST_STAMPS="yyyy-mm-dd"
COMPLETION_WAITING_DOTS=true

# =============================== Path & default editor ===============================
# Ruby Gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"
# Node.js & pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# Custom bin dirs
path=("$HOME/bin" "$HOME/.local/bin" $path)
export PATH

# Use vim for SSH, nvim otherwise
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR=vim
else
  export EDITOR=nvim
fi

# =============================== SSH agent setup ===============================
if [[ -z $SSH_AUTH_SOCK ]] || ! ssh-add -l &>/dev/null; then
  eval "$(ssh-agent -s)" &>/dev/null
  for key in ~/.ssh/*; do
    [[ -f $key && ! $key =~ \.pub$ ]] || continue
    ssh-add "$key" &>/dev/null
  done
  ssh-add -l &>/dev/null
fi

# =============================== Aliases & helpers ===============================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias vi='nvim'
alias vim='nvim'

alias py='python3'
alias pip='pip3'

# Enhanced ls with colorls if available
if command -v colorls &> /dev/null; then
  alias ls='colorls'
  alias ll='colorls -l'
  alias la='colorls -la'
  alias tree='colorls --tree'
else
  alias ll='ls -l'
  alias la='ls -la'
fi

# apt helpers
install() { sudo apt install -y "$@"; }
update()  { sudo apt update && sudo apt upgrade -y; }
remove()  { sudo apt remove -y "$@"; }
search()  { apt search "$@"; }

# Create & activate a virtualenv (default: .venv)
venv() {
  local name=${1:-.venv}
  [[ -d $name ]] || python3 -m venv "$name" && echo "Created venv '$name'."
  source "$name/bin/activate" && echo "Activated '$name'."
}

# Extract almost any archive
extract() {
  local file=$1
  [[ -f $file ]] || { print -P "%F{red}✗%f '$file' not found"; return 1; }
  case $file in
    *.tar.bz2) tar -xjf "$file" ;;
    *.tar.gz)  tar -xzf "$file" ;;
    *.tar.xz)  tar -xJf "$file" ;;
    *.tar)     tar -xf "$file" ;;
    *.zip)     unzip "$file" ;;
    *.7z)      7z x  "$file" ;;
    *.rar)     unrar x "$file" ;;
    *.bz2)     bunzip2 "$file" ;;
    *.gz)      gunzip  "$file" ;;
    *)         echo "Cannot extract '$file'" ;;
  esac
}

# Print file checksums (md5, sha1, sha256)
hash_file() {
  local file=$1
  [[ -f $file ]] || { echo "'$file' not found"; return 1; }
  for algo in md5sum sha1sum sha256sum; do
    printf "%s: %s\n" "${algo:t}" "$($algo "$file" | cut -d' ' -f1)"
  done
}

# =============================== Powerlevel10k config ===============================
[[ -f "${XDG_CONFIG_HOME}/.p10k.zsh" ]] && source "${XDG_CONFIG_HOME}/.p10k.zsh"

# pnpm
export PNPM_HOME="/home/vakesz/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

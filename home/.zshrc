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
# Locale settings to fix Perl warnings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

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
typeset -U path PATH fpath FPATH
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then path=($PNPM_HOME $path); fi
path=($HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin /usr/local/go/bin $path $HOME/.deno/env $HOME/.deno/bin)
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then alias fd='fdfind'; fi
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then alias bat='batcat'; fi

if command -v nvim >/dev/null 2>&1; then export EDITOR="nvim" VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then export EDITOR="vim" VISUAL="vim"
else export EDITOR="nano" VISUAL="nano"; fi

export WORKON_HOME="$HOME/.virtualenvs"
if command -v javac >/dev/null 2>&1; then export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"; fi
export LESS='-R' CLICOLOR=1

# --- FZF defaults ------------------------------------------------------------
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob !.git/*'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview-window=right:50%:hidden --bind=shift-right:preview-page-down,shift-left:preview-page-up,ctrl-/:toggle-preview'

# --- Helper: alias only if command exists ------------------------------------
alias_if_exists() { command -v "$2" >/dev/null 2>&1 && alias "$1"="$3"; }

# --- Aliases -----------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias py='python3'
alias pip='pip3'

# lsd / ls
type lsd >/dev/null 2>&1 && alias ls='lsd --group-dirs=first --icon=always' ll='lsd -l --group-dirs=first --icon=always' la='lsd -la --group-dirs=first --icon=always'

# grep
command -v rg >/dev/null 2>&1 && alias grep='rg -n --smart-case'

# python / lint / test
alias_if_exists pc pre-commit 'pre-commit'
alias_if_exists pca pre-commit 'pre-commit autoupdate'
alias_if_exists pcr pre-commit 'pre-commit run -a'
alias_if_exists blackf black 'black .'
alias_if_exists rufff ruff 'ruff check --fix .'
alias_if_exists pt pytest 'pytest -q'
fmtall() {
  command -v ruff >/dev/null && ruff check --fix .
  command -v black >/dev/null && black .
  command -v prettier >/dev/null && prettier -w .
  command -v eslint >/dev/null && eslint . --fix || true
  if command -v clang-format >/dev/null; then
    local patterns=("**/*.c" "**/*.cc" "**/*.cpp" "**/*.h" "**/*.hh" "**/*.hpp")
    for p in ${patterns[@]}; do
      for f in ${(~)p}; do [ -f "$f" ] && clang-format -i "$f"; done
    done
  fi
}

# azure
alias azlogin='az login'
alias azsubs='az account list -o table'
azuse() { az account set -s "$1"; }

# misc
alias scan='nmap -sC -sV'
alias_if_exists wrk1m wrk 'wrk -t4 -c64 -d60s'
alias_if_exists upgrade topgrade 'topgrade -y'

mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
  local f="$1"; [ -f "$f" ] || { echo "No such file: $f"; return 1; }
  case "$f" in
    *.tar.bz2) tar xjf "$f" ;;
    *.tar.gz) tar xzf "$f" ;;
    *.tar.xz) tar xJf "$f" ;;
    *.tar) tar xf "$f" ;;
    *.tbz2) tar xjf "$f" ;;
    *.tgz) tar xzf "$f" ;;
    *.bz2) bunzip2 "$f" ;;
    *.gz) gunzip "$f" ;;
    *.zip) unzip "$f" ;;
    *.rar) unrar x "$f" ;;
    *.7z) 7z x "$f" ;;
    *) echo "Don't know how to extract '$f'"; return 1 ;;
  esac
}

alias v='${EDITOR:-vi}'
PROMPT_DIRTRIM=3
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# =============================== Powerlevel10k config ===============================
[[ -f "${XDG_CONFIG_HOME}/.p10k.zsh" ]] && source "${XDG_CONFIG_HOME}/.p10k.zsh"

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

# --- Paths & core environment -------------------------------------------------
typeset -U path PATH fpath FPATH
export PNPM_HOME="$HOME/.local/share/pnpm"
# Homebrew path setup (cross-platform)
if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d ~/.linuxbrew ]]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
fi

# Prepend important user paths (order matters)
local _user_paths=($PNPM_HOME $HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin /usr/local/go/bin $HOME/.deno/env $HOME/.deno/bin)
for _p in "${_user_paths[@]}"; do [ -d "$_p" ] && path=($_p $path); done
unset _p _user_paths

have fdfind && ! have fd && alias fd='fdfind'
have batcat && ! have bat && alias bat='batcat'

if have nvim; then export EDITOR=nvim VISUAL=nvim
elif have vim; then export EDITOR=vim VISUAL=vim
else export EDITOR=nano VISUAL=nano; fi

export WORKON_HOME="$HOME/.virtualenvs"
if have javac; then export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"; fi
export LESS='-R' CLICOLOR=1

# --- Starship prompt ----------------------------------------------------------
if have starship; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
fi

# --- Plugin management with manual sourcing -----------------------------------
# Zsh autosuggestions
if [[ -f $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Fast syntax highlighting
if [[ -f $HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
    source $HOMEBREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

# Zsh completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# --- Completion & prompt init -------------------------------------------------
mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit promptinit
compinit -d "$XDG_CACHE_HOME/zsh/compdump" -C
promptinit
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh"

# --- FZF configuration --------------------------------------------------------
if have fd; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif have rg; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob !.git/*'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview-window=right:50%:hidden --bind=shift-right:preview-page-down,shift-left:preview-page-up,ctrl-/:toggle-preview'

# --- Aliases: navigation ------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Aliases: python & tooling ------------------------------------------------
alias py='python3'
alias pip='pip3'
alias_if_exists pc  pre-commit 'pre-commit'
alias_if_exists pca pre-commit 'pre-commit autoupdate'
alias_if_exists pcr pre-commit 'pre-commit run -a'
alias_if_exists blackf black 'black .'
alias_if_exists rufff  ruff  'ruff check --fix .'
alias_if_exists pt    pytest 'pytest -q'

# --- Aliases: listing / search ------------------------------------------------
have lsd && alias ls='lsd --group-dirs=first --icon=always'
have lsd && alias ll='lsd -l --group-dirs=first --icon=always'
have lsd && alias la='lsd -la --group-dirs=first --icon=always'
have rg  && alias grep='rg -n --smart-case'

# --- Aliases: cloud & misc ----------------------------------------------------
alias azlogin='az login'
alias azsubs='az account list -o table'
azuse() { az account set -s "$1"; }
alias scan='nmap -sC -sV'
alias_if_exists wrk1m wrk 'wrk -t4 -c64 -d60s'
alias_if_exists upgrade topgrade 'topgrade -y'

# --- Functions ----------------------------------------------------------------
fmtall() {
  have ruff      && ruff check --fix .
  have black     && black .
  have prettier  && prettier -w .
  have eslint    && eslint . --fix || true
  if have clang-format; then
    local patterns=("**/*.c" "**/*.cc" "**/*.cpp" "**/*.h" "**/*.hh" "**/*.hpp")
    for p in "${patterns[@]}"; do
      for f in ${(~)p}; do [ -f "$f" ] && clang-format -i "$f"; done
    done
  fi
}
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
  local f="$1"; [ -f "$f" ] || { echo "No such file: $f"; return 1; }
  case "$f" in
    *.tar.bz2|*.tbz2) tar xjf "$f" ;;
    *.tar.gz|*.tgz)   tar xzf "$f" ;;
    *.tar.xz)         tar xJf "$f" ;;
    *.tar)            tar xf  "$f" ;;
    *.bz2)            bunzip2 "$f" ;;
    *.gz)             gunzip  "$f" ;;
    *.zip)            unzip   "$f" ;;
    *.rar)            unrar x "$f" ;;
    *.7z)             7z x    "$f" ;;
    *) echo "Don't know how to extract '$f'"; return 1 ;;
  esac
}
venv() {
  [ -d .venv ] || python3 -m venv .venv
  # shellcheck disable=SC1091
  source .venv/bin/activate
}

# --- Editor shortcut ----------------------------------------------------------
alias v='${EDITOR:-vi}'
PROMPT_DIRTRIM=3
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# ~/.zshrc – Zsh configuration file
[[ $- != *i* ]] && return

# ----------------------------------------------------------------------------
# Core framework: Oh My Zsh
#   - Install if missing, then source its main script
# ----------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
if [[ ! -d $ZSH ]]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi
source "$ZSH/oh-my-zsh.sh"


# ----------------------------------------------------------------------------
# Plugin Manager: zplug
#   - Quiet logging, auto-install missing plugins, and compile cache
# ----------------------------------------------------------------------------
export ZPLUG_LOG_LEVEL=ERROR
export ZPLUG_HOME="$HOME/.zplug"

if [[ ! -d $ZPLUG_HOME ]]; then
  git clone https://github.com/zplug/zplug "$ZPLUG_HOME"
  source "$ZPLUG_HOME/init.zsh"
  zplug install --all --jobs=4
  zplug compile
fi

# Initialize zplug and load installed plugins
source "$ZPLUG_HOME/init.zsh"

# ----------------------------------------------------------------------------
# Performance: Fast completion and prompt initialization with caching
# ----------------------------------------------------------------------------
autoload -Uz compinit promptinit
compinit -u -C                # Unsafe mode with cache
promptinit

# Enable on-disk caching for completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ----------------------------------------------------------------------------
# Theme & Deferred Plugins
# ----------------------------------------------------------------------------
# Spaceship Prompt (theme) – deferred for faster startup
zplug "denysdovhan/spaceship-prompt", as:theme, defer:2

# Customize Spaceship segments and symbols
export SPACESHIP_PROMPT_ORDER=(
  user host dir git package node python venv char
)
export SPACESHIP_CHAR_PREFIX="\n"
export SPACESHIP_CHAR_SYMBOL="❯"
export SPACESHIP_CHAR_SUFFIX=" "
export SPACESHIP_DIR_TRUNC=2
export SPACESHIP_CACHE_JOINED=true
export SPACESHIP_CACHE_CONTROL=true

# Asynchronous support for plugins
zplug "mafredri/zsh-async", defer:2

# Essential Oh My Zsh plugins (loaded from upstream)
zplug "plugins/git",             from:oh-my-zsh
zplug "plugins/history",         from:oh-my-zsh
zplug "plugins/colored-man-pages", from:oh-my-zsh
zplug "plugins/command-not-found",  from:oh-my-zsh
zplug "plugins/python",            from:oh-my-zsh

# Deferred community plugins
zplug "zsh-users/zsh-autosuggestions", defer:3
zplug "zsh-users/zsh-completions",    defer:3
zplug "zdharma-continuum/fast-syntax-highlighting", defer:3

# Auto-install any missing plugins and rebuild cache
if ! zplug check; then
  echo "→ Installing missing zplug plugins…"
  zplug install --jobs=4
  zplug compile
fi

# Load plugins and theme silently
zplug load

# ----------------------------------------------------------------------------
# Internationalization: Locale settings
# ----------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# ----------------------------------------------------------------------------
# Command History: size, formatting, and behavior
# ----------------------------------------------------------------------------
HISTSIZE=50000
SAVEHIST=50000
HIST_STAMPS="yyyy-mm-dd"

# History options to avoid duplicates and clutter
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP

# Show dots while waiting for completion
COMPLETION_WAITING_DOTS=true

# ----------------------------------------------------------------------------
# Path & Editor Configuration
# ----------------------------------------------------------------------------
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
# Use vim over SSH or neovim locally
export EDITOR=$([[ -n $SSH_CONNECTION ]] && echo vim || echo nvim)

# ----------------------------------------------------------------------------
# SSH Agent Setup (WSL-friendly)
# ----------------------------------------------------------------------------
if [[ -z $SSH_AUTH_SOCK ]] || ! ssh-add -l &>/dev/null; then
  eval "$(ssh-agent -s)" &>/dev/null
  setopt nullglob
  for key in ~/.ssh/*; do
    [[ -f $key && $key != *.pub ]] && ssh-add "$key" &>/dev/null
  done
  unsetopt nullglob
fi

# ----------------------------------------------------------------------------
# Aliases & Utility Functions
# ----------------------------------------------------------------------------
# Shortcuts for Python and pip
alias py='python3'
alias pip='pip3'

# Apt package management helpers
install() { sudo apt install -y "$@"; }
update()  { sudo apt update && sudo apt upgrade -y; }
remove()  { sudo apt remove -y "$@"; }
search()  { apt search "$@"; }

# Virtual environment management
venv() {
  local name=${1:-.venv}
  if [[ ! -d $name ]]; then
    python3 -m venv "$name" && echo "Created venv '$name'."
  fi
  source "$name/bin/activate" && echo "Activated '$name'."
}

# Archive extraction helper
eextract() {
  local file=$1
  [[ -f $file ]] || { echo "'$file' not found"; return; }
  case $file in
    *.tar.bz2) tar -jxvf "$file" ;; 
    *.tar.gz)  tar -zxvf "$file" ;; 
    *.zip)     unzip    "$file" ;; 
    *.7z)      7z x     "$file" ;; 
    *.rar)     unrar x  "$file" ;; 
    *.bz2)     bunzip2  "$file" ;; 
    *.gz)      gunzip   "$file" ;; 
    *.tar)     tar -xvf "$file" ;; 
    *)         echo "Cannot extract '$file'" ;; 
  esac
}

# Compute file checksums (MD5, SHA1, SHA256)
hash_file() {
  local file=$1
  [[ -f $file ]] || { echo "'$file' not found"; return; }
  for algo in md5sum sha1sum sha256sum; do
    printf "%s: %s
" "${algo^^}" "$(\$algo "$file" | cut -d' ' -f1)"
  done
}

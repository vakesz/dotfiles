# ~/.zshrc – Zsh configuration file
[[ $- != *i* ]] && return

# ──────────────────────────────────────────────────────────────────────────────
# Only update Oh My Zsh & zplug when OMZ itself changes
# ──────────────────────────────────────────────────────────────────────────────

ZSH="$HOME/.oh-my-zsh"
ZPLUG_HOME="$HOME/.zplug"
LAST_OMZ_COMMIT_FILE="$HOME/.zsh_last_omz_commit"

# Clone OMZ if missing
if [[ ! -d $ZSH ]]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

# Fetch remote OMZ commit
git -C "$ZSH" fetch --quiet
remote_sha=$(git -C "$ZSH" rev-parse origin/master)
if [[ -f $LAST_OMZ_COMMIT_FILE ]]; then
  last_sha=$(<"$LAST_OMZ_COMMIT_FILE")
else
  last_sha=""
fi

# If OMZ updated, pull and update zplug
if [[ $remote_sha != "$last_sha" ]]; then
  echo "→ Oh My Zsh updated; pulling changes…"
  git -C "$ZSH" pull --ff-only --quiet origin master
  echo "$remote_sha" > "$LAST_OMZ_COMMIT_FILE"

  if [[ -d $ZPLUG_HOME ]]; then
    echo "→ Updating zplug…"
    git -C "$ZPLUG_HOME" pull --ff-only --quiet origin master
  else
    echo "→ Installing zplug…"
    git clone https://github.com/zplug/zplug "$ZPLUG_HOME"
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# Source core frameworks
# ──────────────────────────────────────────────────────────────────────────────
# Disable compfix prompt (we’ll cache completions below)
export ZSH_DISABLE_COMPFIX=true
source "$ZSH/oh-my-zsh.sh"

# Initialize zplug
source "$ZPLUG_HOME/init.zsh"

# ──────────────────────────────────────────────────────────────────────────────
# Lazily load Oh My Zsh built-in plugins via zplug (from local path)
# ──────────────────────────────────────────────────────────────────────────────
zplug "$ZSH/plugins/git/git.plugin.zsh",               from:local, as:plugin, defer:2
zplug "$ZSH/plugins/history/history.plugin.zsh",       from:local, as:plugin, defer:2
zplug "$ZSH/plugins/colored-man-pages/colored-man-pages.plugin.zsh", from:local, as:plugin, defer:3
zplug "$ZSH/plugins/command-not-found/command-not-found.plugin.zsh", from:local, as:plugin, defer:3
zplug "$ZSH/plugins/python/python.plugin.zsh",         from:local, as:plugin, defer:2

# ──────────────────────────────────────────────────────────────────────────────
# Lazily load community plugins & theme
# ──────────────────────────────────────────────────────────────────────────────
zplug "denysdovhan/spaceship-prompt",               as:theme, defer:2
zplug "mafredri/zsh-async",                         defer:2
zplug "zsh-users/zsh-autosuggestions",              defer:3
zplug "zsh-users/zsh-completions",                  defer:3
zplug "zdharma-continuum/fast-syntax-highlighting", defer:3

# ──────────────────────────────────────────────────────────────────────────────
# Auto-install any missing remote plugins
# ──────────────────────────────────────────────────────────────────────────────
if ! zplug check --verbose; then
  echo "→ Installing missing zplug plugins…"
  zplug install
fi

# Load all zplug-managed plugins & theme
zplug load

# ──────────────────────────────────────────────────────────────────────────────
# Performance: Fast completion & prompt init with caching
# ──────────────────────────────────────────────────────────────────────────────
autoload -Uz compinit promptinit
compinit -u -C               # cache completions, unsafe mode
promptinit

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ──────────────────────────────────────────────────────────────────────────────
# Theme Configuration: Spaceship Prompt
# ──────────────────────────────────────────────────────────────────────────────
export SPACESHIP_PROMPT_ORDER=(
  user host dir git package node python venv char
)
export SPACESHIP_CHAR_PREFIX="\n"
export SPACESHIP_CHAR_SYMBOL="❯"
export SPACESHIP_CHAR_SUFFIX=" "
export SPACESHIP_DIR_TRUNC=2
export SPACESHIP_CACHE_JOINED=true
export SPACESHIP_CACHE_CONTROL=true

# ──────────────────────────────────────────────────────────────────────────────
# Internationalization: Locale settings
# ──────────────────────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# ──────────────────────────────────────────────────────────────────────────────
# Command History: size, formatting, and behavior
# ──────────────────────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HIST_STAMPS="yyyy-mm-dd"
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS \
       HIST_IGNORE_SPACE HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS HIST_BEEP
COMPLETION_WAITING_DOTS=true

# ──────────────────────────────────────────────────────────────────────────────
# Path & Editor Configuration
# ──────────────────────────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export EDITOR=$([[ -n $SSH_CONNECTION ]] && echo vim || echo nvim

)

# ──────────────────────────────────────────────────────────────────────────────
# SSH Agent Setup (WSL-friendly)
# ──────────────────────────────────────────────────────────────────────────────
if [[ -z $SSH_AUTH_SOCK ]] || ! ssh-add -l &>/dev/null; then
  eval "$(ssh-agent -s)" &>/dev/null
  setopt nullglob
  for key in ~/.ssh/*; do
    [[ -f $key && $key != *.pub ]] && ssh-add "$key" &>/dev/null
  done
  unsetopt nullglob
fi

# ──────────────────────────────────────────────────────────────────────────────
# Aliases & Utility Functions
# ──────────────────────────────────────────────────────────────────────────────
alias py='python3'
alias pip='pip3'

install() { sudo apt install -y "$@"; }
update()  { sudo apt update && sudo apt upgrade -y; }
remove()  { sudo apt remove -y "$@"; }
search()  { apt search "$@"; }

venv() {
  local name=${1:-.venv}
  [[ -d $name ]] || python3 -m venv "$name" && echo "Created venv '$name'."
  source "$name/bin/activate" && echo "Activated '$name'."
}

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

hash_file() {
  local file=$1
  [[ -f $file ]] || { echo "'$file' not found"; return; }
  for algo in md5sum sha1sum sha256sum; do
    printf "%s: %s\n" "${algo^^}" "$($algo "$file" | cut -d' ' -f1)"
  done
}

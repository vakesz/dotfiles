# ─────────────────────────────────────────────────────────────────────────────
# zplug - Plugin Manager
# ─────────────────────────────────────────────────────────────────────────────
if [[ ! -d ~/.zplug ]]; then
  echo "zplug not found. Installing..."
  git clone https://github.com/zplug/zplug ~/.zplug
fi

source ~/.zplug/init.zsh

# Load theme
zplug "themes/robbyrussell", from:oh-my-zsh, as:theme

# Load plugins from oh-my-zsh
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/history", from:oh-my-zsh
zplug "plugins/colored-man-pages", from:oh-my-zsh
zplug "plugins/command-not-found", from:oh-my-zsh
zplug "plugins/python", from:oh-my-zsh

# Load external plugins
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "zdharma-continuum/fast-syntax-highlighting", defer:2

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
  printf "Install zplug plugins? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi

# Load plugins
zplug load

# Enable completions
autoload -U compinit && compinit

# ─────────────────────────────────────────────────────────────────────────────
# Locales
# ─────────────────────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# ─────────────────────────────────────────────────────────────────────────────
# History
# ─────────────────────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HIST_STAMPS="yyyy-mm-dd"

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP
COMPLETION_WAITING_DOTS=true

# ─────────────────────────────────────────────────────────────────────────────
# PATH & Editor
# ─────────────────────────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# ─────────────────────────────────────────────────────────────────────────────
# SSH Agent (WSL-friendly)
# ─────────────────────────────────────────────────────────────────────────────
if [[ -z "$SSH_AUTH_SOCK" ]] || ! ssh-add -l &>/dev/null; then
  eval "$(ssh-agent -s)" &>/dev/null
  setopt nullglob
  for key in ~/.ssh/*; do
    [[ -f $key && $key != *.pub ]] && ssh-add "$key" &>/dev/null
  done
  unsetopt nullglob
fi

# ─────────────────────────────────────────────────────────────────────────────
# Aliases & Functions
# ─────────────────────────────────────────────────────────────────────────────

## Python
alias py='python3'
alias pip='pip3'

## APT helpers
install() { sudo apt install -y "$@"; }
update()  { sudo apt update && sudo apt upgrade -y; }
remove()  { sudo apt remove "$@"; }
search()  { apt search "$@"; }

## Virtual environments
venv() {
  local name=${1:-.venv}
  [[ -d $name ]] || python3 -m venv "$name" && echo "Created venv '$name'."
  source "$name/bin/activate" && echo "Activated '$name'."
}

## Archive extraction
extract() {
  [[ -f $1 ]] || { echo "'$1' not found"; return; }
  case $1 in
    *.tar.bz2) tar -jxvf "$1" ;;
    *.tar.gz)  tar -zxvf "$1" ;;
    *.zip)     unzip    "$1" ;;
    *.7z)      7z x     "$1" ;;
    *.rar)     unrar x  "$1" ;;
    *.bz2)     bunzip2  "$1" ;;
    *.gz)      gunzip   "$1" ;;
    *.tar)     tar -xvf "$1" ;;
    *)         echo "Cannot extract '$1'" ;;
  esac
}

## File hashing
hash_file() {
  for algo in md5 sha1 sha256; do
    printf "%s: %s\n" "${algo^^}" "$($algo"sum" "$1" | cut -d' ' -f1)"
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# End of ~/.zshrc
# ─────────────────────────────────────────────────────────────────────────────

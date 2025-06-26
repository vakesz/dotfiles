# ─────────────────────────────────────────────────────────────────────────────
# Oh My Zsh
# ─────────────────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
  git
  history
  colored-man-pages
  command-not-found
  zsh-autosuggestions
  zsh-completions
  fast-syntax-highlighting
  python
)

autoload -U compinit && compinit
source "$ZSH/oh-my-zsh.sh"

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
  for key in ~/.ssh/*; do
    [[ -f $key && $key != *.pub ]] && ssh-add "$key" &>/dev/null
  done
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

# ─────────────────────────────────────────────────────────────────────────────
# Oh My Zsh core
# ─────────────────────────────────────────────────────────────────────────────
# Set the installation directory for Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# If the main Oh My Zsh script exists, source it to initialize
if [[ -s "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"      # Load Oh My Zsh configuration and themes
else
  # Warn if Oh My Zsh is missing or path is incorrect
  echo "Warning: Oh My Zsh not found in $ZSH"
fi

# ─────────────────────────────────────────────────────────────────────────────
# zplug - Plugin Manager
# ─────────────────────────────────────────────────────────────────────────────
# Define zplug installation directory
export ZPLUG_HOME="$HOME/.zplug"

# Clone zplug repository if it's not already installed
if [[ ! -d "$ZPLUG_HOME" ]]; then
  git clone https://github.com/zplug/zplug "$ZPLUG_HOME"
fi

# Source zplug to enable plugin management
source "$ZPLUG_HOME/init.zsh"

# ─────────────────────────────────────────────────────────────────────────────
# zplug-managed theme & plugins
# ─────────────────────────────────────────────────────────────────────────────
# Defer loading of async helper for speed
zplug "mafredri/zsh-async", defer:1

# Load the robbyrussell theme (from Oh My Zsh)
zplug "themes/robbyrussell", from:oh-my-zsh, as:theme

# Load useful Oh My Zsh plugins
zplug "plugins/git",             from:oh-my-zsh    # Git shortcuts & helpers
zplug "plugins/history",         from:oh-my-zsh    # Enhanced history search
zplug "plugins/colored-man-pages", from:oh-my-zsh # Colorize man pages
zplug "plugins/command-not-found",  from:oh-my-zsh # Suggest commands for typos
zplug "plugins/python",            from:oh-my-zsh # Python environment helpers

# Additional community plugins
zplug "zsh-users/zsh-autosuggestions"        # Suggest commands as you type
zplug "zsh-users/zsh-completions"            # Additional tab completions
zplug "zdharma-continuum/fast-syntax-highlighting", defer:2 # Highlight commands fast

# Prompt to install any missing plugins interactively
if ! zplug check --verbose; then
  printf "Install missing plugins? [y/N]: "
  if read -q; then
    echo
    zplug install                    # Install requested plugins
  fi
fi

# Load all configured plugins and themes
zplug load

# ─────────────────────────────────────────────────────────────────────────────
# Locales
# ─────────────────────────────────────────────────────────────────────────────
# Ensure consistent language and encoding settings across applications
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# ─────────────────────────────────────────────────────────────────────────────
# History settings
# ─────────────────────────────────────────────────────────────────────────────
# Number of commands to keep in memory and on disk
HISTSIZE=50000; SAVEHIST=50000; HIST_STAMPS="yyyy-mm-dd"

# Configure history behavior
setopt HIST_EXPIRE_DUPS_FIRST    # Remove older duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record duplicate entries
setopt HIST_IGNORE_ALL_DUPS      # Remove older occurrences of duplicated commands
setopt HIST_IGNORE_SPACE         # Ignore commands starting with a space
setopt HIST_FIND_NO_DUPS         # Skip duplicates when searching history
setopt HIST_SAVE_NO_DUPS         # Don't write duplicates to history file
setopt HIST_BEEP                 # Audible bell on history expansion
setopt SHARE_HISTORY             # Share history across multiple shells
setopt INC_APPEND_HISTORY        # Append commands to history immediately

# Visual indicator while waiting for completion
COMPLETION_WAITING_DOTS=true

# ─────────────────────────────────────────────────────────────────────────────
# PATH & EDITOR
# ─────────────────────────────────────────────────────────────────────────────
# Prepend local bin directories to PATH for priority execution
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Choose default editor based on SSH connection
export EDITOR=$([[ -n $SSH_CONNECTION ]] && echo vim || echo nvim)

# ─────────────────────────────────────────────────────────────────────────────
# SSH Agent (WSL-friendly)
# ─────────────────────────────────────────────────────────────────────────────
# Start ssh-agent if not already running and add all private keys
if [[ -z "$SSH_AUTH_SOCK" ]] || ! ssh-add -l &>/dev/null; then
  eval "$(ssh-agent -s)" &>/dev/null
  setopt nullglob                  # Allow empty glob expansions

  # Automatically add each private key from ~/.ssh
  for key in ~/.ssh/*; do
    if [[ -f $key && $key != *.pub ]]; then
      ssh-add "$key" &>/dev/null
    fi
  done
  unsetopt nullglob                # Restore default globbing
fi

# ─────────────────────────────────────────────────────────────────────────────
# Aliases & Functions
# ─────────────────────────────────────────────────────────────────────────────
# Shorten python and pip commands
alias py='python3'
alias pip='pip3'

# Apt helpers for installing, updating, removing, and searching packages
install() { sudo apt install -y "$@"; }
update()  { sudo apt update && sudo apt upgrade -y; }
remove()  { sudo apt remove "$@"; }
search()  { apt search "$@"; }

# Create and activate a virtual environment conveniently
venv() {
  local name=${1:-.venv}
  [[ -d $name ]] || python3 -m venv "$name" && echo "Created venv '$name'."
  source "$name/bin/activate" && echo "Activated '$name'."
}

# Extract archives of various formats with a single function
extract() {
  [[ -f $1 ]] || { echo "'$1' not found"; return; }
  case $1 in
    *.tar.bz2) tar -jxvf "$1" ;;    # bzip2 compressed
    *.tar.gz)  tar -zxvf "$1" ;;    # gzip compressed
    *.zip)     unzip    "$1" ;;    # zip archives
    *.7z)      7z x     "$1" ;;    # 7zip archives
    *.rar)     unrar x  "$1" ;;    # rar archives
    *.bz2)     bunzip2  "$1" ;;    # decompress bzip2 file
    *.gz)      gunzip   "$1" ;;    # decompress gzip file
    *.tar)     tar -xvf "$1" ;;    # uncompressed tar archive
    *)         echo "Cannot extract '$1'" ;;  # unsupported format
  esac
}

# Compute checksums (MD5, SHA1, SHA256) for a given file
hash_file() {
  for algo in md5 sha1 sha256; do
    printf "%s: %s\n" "${algo^^}" "$("${algo}sum" "$1" | cut -d' ' -f1)"
  done
}
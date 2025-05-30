# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set locale environment variables early to prevent warnings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

# History configuration
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
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

# Load completions
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

# User configuration

# Start ssh-agent in WSL and add keys from ~/.ssh/
if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l &>/dev/null; then
  eval "$(ssh-agent -s)" > /dev/null

  # Check if SSH directory exists and has private keys
  if [ -d ~/.ssh ]; then
    for key in ~/.ssh/*; do
      # Check if the glob matched actual files and if it's a private key
      if [[ -f "$key" && "$key" != *.pub ]]; then
        ssh-add "$key" &>/dev/null
      fi
    done
  fi
fi

# Modern alternatives aliases
if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# Development aliases
alias py='python3'
alias pip='pip3'

# Improved apt wrapper functions
function install() {
    sudo apt install -y $@
}

function update() {
    sudo apt update && sudo apt upgrade -y
}

function remove() {
    sudo apt remove $@
}

function search() {
    apt search $@
}

# Generate locales if not present (helps prevent warnings)
function check_locale() {
    if ! locale -a | grep -qE "(en_US\.utf8|en_US\.UTF-8)"; then
        echo "Generating en_US.UTF-8 locale..."
        sudo locale-gen en_US.UTF-8 2>/dev/null
        sudo update-locale LANG=en_US.UTF-8 2>/dev/null
        echo "Locale generated. Please restart your shell or run 'source ~/.zshrc'"
    fi
}

# Check and fix locale on shell startup
check_locale

# File hash functions
function hash_file() {
    echo "MD5:    $(md5sum $1 | cut -d ' ' -f1)"
    echo "SHA1:   $(sha1sum $1 | cut -d ' ' -f1)"
    echo "SHA256: $(sha256sum $1 | cut -d ' ' -f1)"
}

# Extract various compressed file types
function extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)  tar -jxvf $1                        ;;
            *.tar.gz)   tar -zxvf $1                        ;;
            *.bz2)      bunzip2 $1                          ;;
            *.gz)       gunzip $1                           ;;
            *.tar)      tar -xvf $1                         ;;
            *.tbz2)     tar -jxvf $1                        ;;
            *.tgz)      tar -zxvf $1                        ;;
            *.zip)      unzip $1                            ;;
            *.Z)        uncompress $1                       ;;
            *.7z)       7z x $1                             ;;
            *.rar)      unrar x $1                          ;;
            *)          echo "'$1' cannot be extracted"     ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}


# Add local bin to path
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
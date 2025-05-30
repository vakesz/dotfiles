# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

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
  python
)

source $ZSH/oh-my-zsh.sh

# User configuration

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

# Useful aliases
alias ll='ls -laF'
alias la='ls -A'
alias l='ls -CF'
alias zshrc='${EDITOR:-vim} ~/.zshrc'
alias gitc='${EDITOR:-vim} ~/.gitconfig'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias myip='curl -s ipinfo.io/ip'
alias ipinfo='curl -s ipinfo.io'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

# Add local bin to path
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Set larger history
HISTSIZE=10000
SAVEHIST=10000

# ============================================================================
# Aliases and Functions
# ============================================================================

# ----------------------------------------------------------------------------
# Platform-Specific Command Aliases
# ----------------------------------------------------------------------------

if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  # Fix Ubuntu naming differences
  alias_if_exists fd fdfind fdfind
  alias_if_exists bat batcat batcat
fi

# ----------------------------------------------------------------------------
# Editor Aliases
# ----------------------------------------------------------------------------

if have nvim; then
  alias vi='nvim'
  alias vim='nvim'
  alias v='nvim'
fi

# ----------------------------------------------------------------------------
# Python Aliases
# ----------------------------------------------------------------------------

alias python='python3.13'
alias python3='python3.13'
alias pip='pip3.13'
alias pip3='pip3.13'
alias py='python3.13'

# Python virtual environment helper
venv() {
  if [[ -d .venv ]]; then
    source .venv/bin/activate
  else
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
  fi
}

# Deactivate virtual environment
alias venv-off='deactivate'

# ----------------------------------------------------------------------------
# Directory Navigation
# ----------------------------------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# List directory contents
alias l='ls -lFh'     # size, show type, human readable
alias la='ls -lAFh'   # long list, show almost all, show type, human readable
alias lr='ls -tRFh'   # sorted by date, recursive, show type, human readable
alias lt='ls -ltFh'   # long list, sorted by date, show type, human readable
alias ll='ls -l'      # long list
alias ldot='ls -ld .*'

# Use lsd if available
if have lsd; then
  alias ls='lsd'
  alias l='lsd -lFh'
  alias la='lsd -lAFh'
  alias lt='lsd -ltFh'
  alias tree='lsd --tree'
fi

# ----------------------------------------------------------------------------
# Git Aliases (Supplementary to OMZ git plugin)
# ----------------------------------------------------------------------------

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpl='git pull'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias ga='git add'
alias gaa='git add --all'

# ----------------------------------------------------------------------------
# Safety Aliases
# ----------------------------------------------------------------------------

alias rm='rm -i'      # Confirm before removing
alias cp='cp -i'      # Confirm before overwriting
alias mv='mv -i'      # Confirm before overwriting
alias mkdir='mkdir -p' # Create intermediate directories

# ----------------------------------------------------------------------------
# Utility Aliases
# ----------------------------------------------------------------------------

# Clear screen
alias c='clear'
alias cls='clear'

# Find large files
alias findbig='du -h -d 1 | sort -hr | head -20'

# Human-readable sizes
alias df='df -h'
alias du='du -h'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Process management
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias psme='ps -u $USER -o pid,stat,pcpu,pmem,comm'

# Network
alias ports='netstat -tulanp'
alias myip='curl -s https://api.ipify.org && echo'
alias localip='ipconfig getifaddr en0'  # macOS
if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  alias localip='hostname -I | awk "{print \$1}"'
fi

# Reload zsh config
alias reload='source $ZDOTDIR/.zshrc'

# Edit zsh config
alias zshconfig='$EDITOR $ZDOTDIR/.zshrc'
alias zshenv='$EDITOR $ZDOTDIR/.zshenv'

# ----------------------------------------------------------------------------
# Development Shortcuts
# ----------------------------------------------------------------------------

# Docker
if have docker; then
  alias d='docker'
  alias dc='docker compose'
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dex='docker exec -it'
  alias dlog='docker logs -f'
  alias dprune='docker system prune -af --volumes'
fi

# Kubernetes
if have kubectl; then
  alias k='kubectl'
  alias kg='kubectl get'
  alias kd='kubectl describe'
  alias kdel='kubectl delete'
  alias kl='kubectl logs'
  alias kx='kubectl exec -it'
fi

# Make
if have make; then
  alias m='make'
  alias mr='make run'
  alias mb='make build'
  alias mt='make test'
fi

# ----------------------------------------------------------------------------
# Quick Directory Access
# ----------------------------------------------------------------------------

alias home='cd ~'
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias down='cd ~/Downloads'
alias dots='cd ~/dotfiles'

# ----------------------------------------------------------------------------
# macOS-Specific Aliases
# ----------------------------------------------------------------------------

if [[ "$OS_TYPE" == "macos" ]]; then
  # Show/hide hidden files in Finder
  alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

  # Flush DNS cache
  alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

  # Empty trash
  alias emptytrash='sudo rm -rf ~/.Trash/*'

  # Lock screen
  alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
fi

# ----------------------------------------------------------------------------
# Linux-Specific Aliases
# ----------------------------------------------------------------------------

if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  # Service management
  alias services='systemctl list-units --type=service'
fi

# ----------------------------------------------------------------------------
# Update Management (Cross-Platform)
# ----------------------------------------------------------------------------

# Use topgrade for comprehensive updates across all package managers
if have topgrade; then
  alias update='topgrade'
  alias upgrade='topgrade'
else
  # Fallback if topgrade not installed
  if [[ "$OS_TYPE" == "macos" ]]; then
    alias update='brew update && brew upgrade && brew cleanup'
  elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
    alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
  fi
fi

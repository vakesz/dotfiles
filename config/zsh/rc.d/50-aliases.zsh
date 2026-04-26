# Aliases

if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  command_exists fdfind && alias fd=fdfind
fi

if command_exists uv; then
  alias uv-tools='uv tool list'
  alias uv-python='uv python list'
fi

if [[ "$OS_TYPE" == "macos" ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias dots='cd ~/.dotfiles'
alias p='cd ~/projects'

# Git
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gc='git commit'
alias gcan='git commit --amend --no-edit'
alias gcae='git commit --amend'
alias ga='git add'
alias gaa='git add --all'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gpl='git pull'

if command_exists docker; then
  alias dcu='docker compose up'
  alias dcd='docker compose down'
fi
if command_exists podman; then
  alias pcu='podman compose up'
  alias pcd='podman compose down'
fi

command_exists opencode && alias oc='opencode'
command_exists claude && alias cc='claude'

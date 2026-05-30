# Aliases

(( $+commands[fdfind] )) && alias fd=fdfind

if (( $+commands[uv] )); then
  alias uv-tools='uv tool list'
  alias uv-python='uv python list'
fi

if ls --color=auto &>/dev/null; then
  alias ls='ls --color=auto'
else
  alias ls='ls -G'
fi
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias dots='cd ~/.dotfiles'
alias p='cd ~/Code'

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

(( $+commands[docker] )) && {
  alias dcu='docker compose up'
  alias dcd='docker compose down'
}

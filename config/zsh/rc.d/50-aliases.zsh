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
alias c='cd ~/Code'

# Git
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias ga='git add'
alias gp='git push'

(( $+commands[docker] )) && {
  alias dcu='docker compose up'
  alias dcd='docker compose down'
}

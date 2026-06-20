# Aliases

(( $+commands[fdfind] )) && alias fd=fdfind

if (( $+commands[uv] )); then
  alias uv-tools='uv tool list'
  alias uv-python='uv python list'
fi

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2'
else
  if ls --color=auto &>/dev/null; then
    alias ls='ls --color=auto'
  else
    alias ls='ls -G'
  fi
  alias ll='ls -la'
  alias la='ls -A'
  alias l='ls -CF'
fi

# bat is packaged as `batcat` on Debian/Ubuntu.
(( $+commands[batcat] )) && alias bat='batcat'
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat --paging=never'

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

# AI
(( $+commands[claude] )) && alias cc='claude'
(( $+commands[opencode] )) && alias oc='opencode'

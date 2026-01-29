# Aliases and Functions

if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  alias_if_exists fd fdfind fdfind
fi

# Neovim aliases
if have nvim; then
  alias vi='nvim'
  alias vim='nvim'
  alias v='nvim'
fi

# Python (UV)
alias uv-tools='uv tool list'
alias uv-python='uv python list'

# Virtual environment helper using UV
venv() {
  local venv_dir="${1:-.venv}"

  if [[ -f "$venv_dir/bin/activate" ]]; then
    source "$venv_dir/bin/activate"
    return
  fi

  if [[ -d "$venv_dir" ]]; then
    echo "Error: $venv_dir exists but is not a valid virtualenv" >&2
    return 1
  fi

  have uv || { echo "Error: uv not found" >&2; return 1; }
  echo "Creating virtualenv with uv in $venv_dir..."
  uv venv "$venv_dir" && source "$venv_dir/bin/activate"
}

alias venv-off='deactivate'

# Auto-activate/deactivate .venv on directory change
__auto_venv() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_parent="${VIRTUAL_ENV:h}"
    if [[ "$PWD" != "${venv_parent}/"* && "$PWD" != "$venv_parent" ]]; then
      deactivate
    fi
  fi

  if [[ -z "$VIRTUAL_ENV" && -f ".venv/bin/activate" ]]; then
    source .venv/bin/activate
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd __auto_venv
__auto_venv

# Navigation
if [[ "$OS_TYPE" == "macos" ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

alias dots='cd ~/.dotfiles'
alias p='cd ~/projects'

# Git
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gc='git commit'
alias gca='git commit --amend'
alias ga='git add'
alias gaa='git add --all'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gpl='git pull'

# Docker
alias dcu='docker compose up'
alias dcd='docker compose down'

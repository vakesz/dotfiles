# ============================================================================
# Aliases and Functions
# ============================================================================
# Minimal, essential aliases only

# ----------------------------------------------------------------------------
# Platform-Specific Command Aliases
# ----------------------------------------------------------------------------

if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  alias_if_exists fd fdfind fdfind
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
# Python (UV-based)
# ----------------------------------------------------------------------------

alias uv-tools='uv tool list'
alias uv-python='uv python list'

# Virtual environment helper using UV
venv() {
  local venv_dir="${1:-.venv}"

  if [[ -d "$venv_dir" ]]; then
    if [[ -f "$venv_dir/bin/activate" ]]; then
      source "$venv_dir/bin/activate"
    else
      echo "Error: $venv_dir exists but is not a valid virtualenv" >&2
      return 1
    fi
  else
    if ! have uv; then
      echo "Error: uv not found" >&2
      return 1
    fi
    echo "Creating virtualenv with uv in $venv_dir..."
    if uv venv "$venv_dir"; then
      source "$venv_dir/bin/activate"
      # UV manages everything - no need to upgrade pip
    else
      echo "Error: Failed to create virtualenv" >&2
      return 1
    fi
  fi
}

alias venv-off='deactivate'

# Auto-activate .venv on directory change
__auto_venv() {
  # Deactivate if we left a venv directory
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_parent="${VIRTUAL_ENV:h}"
    if [[ "$PWD" != "$venv_parent"* ]]; then
      deactivate
    fi
  fi

  # Activate if .venv exists in current dir
  if [[ -z "$VIRTUAL_ENV" && -f ".venv/bin/activate" ]]; then
    source .venv/bin/activate
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd __auto_venv

# Run once on shell start (for initial directory)
__auto_venv

# ----------------------------------------------------------------------------
# Navigation
# ----------------------------------------------------------------------------

# Colorized ls aliases (macOS uses -G, Linux uses --color=auto)
if [[ "$OS_TYPE" == "macos" ]]; then
  alias ls='ls -G'
  alias ll='ls -laG'
  alias la='ls -AG'
  alias l='ls -CFG'
else
  alias ls='ls --color=auto'
  alias ll='ls -la --color=auto'
  alias la='ls -A --color=auto'
  alias l='ls -CF --color=auto'
fi

alias home='cd ~'
alias dots='cd ~/.dotfiles'
alias p='cd ~/projects'
alias proj='cd ~/projects'

# ----------------------------------------------------------------------------
# Git Aliases
# ----------------------------------------------------------------------------

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

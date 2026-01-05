# ============================================================================
# Aliases and Functions
# ============================================================================
# Minimal, essential aliases only

# ----------------------------------------------------------------------------
# Platform-Specific Command Aliases
# ----------------------------------------------------------------------------

if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
  alias_if_exists fd fdfind fdfind
  alias_if_exists bat batcat batcat
fi

# Use bat instead of cat if available
if have bat; then
  alias cat='bat'
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
# Python
# ----------------------------------------------------------------------------

alias py='python3'

# Virtual environment helper with error handling
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
    if ! have python3; then
      echo "Error: python3 not found" >&2
      return 1
    fi
    echo "Creating virtualenv in $venv_dir..."
    if python3 -m venv "$venv_dir"; then
      source "$venv_dir/bin/activate"
      pip install --upgrade pip --quiet
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
alias dots='cd ~/dotfiles'

# ----------------------------------------------------------------------------
# macOS-Specific
# ----------------------------------------------------------------------------

if [[ "$OS_TYPE" == "macos" ]]; then
  alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
  alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
  alias emptytrash='sudo rm -rf ~/.Trash/*'
  alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
fi

# ============================================================================
# Zinit Plugin Manager
# ============================================================================
# Manages zsh plugins for enhanced shell experience

# ----------------------------------------------------------------------------
# Zinit Installation and Setup
# ----------------------------------------------------------------------------

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not already installed
if [[ ! -d "$ZINIT_HOME" ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing ZINIT (zdharma-continuum/zinit)…%f"
  command mkdir -p "$(dirname $ZINIT_HOME)"
  if command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null; then
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b"
  else
    print -P "%F{160}▓▒░ Zinit installation failed. Plugins disabled.%f%b" >&2
    return 0  # Exit gracefully, continue without plugins
  fi
fi

# Source Zinit with error handling
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
else
  print -P "%F{160}▓▒░ Zinit not found. Plugins disabled.%f%b" >&2
  return 0  # Exit gracefully
fi

# ----------------------------------------------------------------------------
# Zinit Plugins
# ----------------------------------------------------------------------------

# Syntax highlighting - Must be loaded before autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions - Fish-like command suggestions
zinit light zsh-users/zsh-autosuggestions

# Completions - Additional completion definitions
zinit light zsh-users/zsh-completions

# FZF Tab - Replace zsh default completion with fzf
zinit light Aloxaf/fzf-tab

# ----------------------------------------------------------------------------
# Oh-My-Zsh Plugins (via snippets)
# ----------------------------------------------------------------------------

# Git aliases and functions
zinit snippet OMZP::git

# Sudo - Press ESC twice to add sudo to command
zinit snippet OMZP::sudo

# Command-not-found - Suggests package for missing commands
zinit snippet OMZP::command-not-found

# Docker - Docker completion and aliases (if docker is installed)
if have docker; then
  zinit snippet OMZP::docker
  zinit snippet OMZP::docker-compose
fi

# ----------------------------------------------------------------------------
# Additional Tools Integration
# ----------------------------------------------------------------------------

# Zoxide - Smart directory jumping (better cd)
if have zoxide; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# FZF - Fuzzy finder integration
if have fzf; then
  # Key bindings - try new method first, fallback to old method
  if source <(fzf --zsh) 2>/dev/null; then
    :
  elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh 2>/dev/null || true
  elif [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
  fi
fi

# ============================================================================
# Zinit Plugin Manager
# ============================================================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not already installed
if [[ ! -d "$ZINIT_HOME" ]]; then
  print -P "%F{33}Installing Zinit...%f"
  command mkdir -p "$(dirname $ZINIT_HOME)"
  if command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null; then
    print -P "%F{34}Done.%f"
  else
    print -P "%F{160}Failed.%f" >&2
    return 0
  fi
fi

# Source Zinit
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
else
  return 0
fi

# ----------------------------------------------------------------------------
# Plugins (Turbo Mode for deferred loading)
# ----------------------------------------------------------------------------

# Essential - load immediately
zinit light-mode lucid for \
    zsh-users/zsh-autosuggestions

# Syntax highlighting - defer slightly
zinit wait'0a' lucid for \
    zsh-users/zsh-syntax-highlighting

# Completions - defer
zinit wait'0b' lucid blockf for \
    zsh-users/zsh-completions

# FZF Tab - defer after completions
zinit wait'0c' lucid for \
    Aloxaf/fzf-tab

# ----------------------------------------------------------------------------
# Oh-My-Zsh Snippets (deferred)
# ----------------------------------------------------------------------------

zinit wait'1' lucid for \
    OMZP::git \
    OMZP::sudo

zinit wait'2' lucid for \
    OMZP::command-not-found

# ----------------------------------------------------------------------------
# Tool Integrations (cached)
# ----------------------------------------------------------------------------

# Zoxide - cached initialization
if have zoxide; then
  local zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zoxide-init.zsh"
  local zoxide_bin
  zoxide_bin=$(command -v zoxide)
  if [[ ! -f "$zoxide_cache" || "$zoxide_bin" -nt "$zoxide_cache" ]]; then
    mkdir -p "${zoxide_cache:h}"
    zoxide init --cmd cd zsh >| "$zoxide_cache" 2>/dev/null
  fi
  source "$zoxide_cache"
fi

# FZF - cached initialization
if have fzf; then
  local fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/fzf-init.zsh"
  local fzf_bin
  fzf_bin=$(command -v fzf)
  if [[ ! -f "$fzf_cache" || "$fzf_bin" -nt "$fzf_cache" ]]; then
    mkdir -p "${fzf_cache:h}"
    fzf --zsh >| "$fzf_cache" 2>/dev/null
  fi
  [[ -f "$fzf_cache" ]] && source "$fzf_cache"
fi

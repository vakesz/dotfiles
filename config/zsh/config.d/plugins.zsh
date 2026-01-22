# Zinit Plugin Manager

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

if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
else
  return 0
fi

zinit light-mode lucid for \
    zsh-users/zsh-autosuggestions

zinit wait'0a' lucid for \
    zsh-users/zsh-syntax-highlighting

# Cached tool initialization
_lazy_init() {
  local tool="$1" cmd="$2"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${tool}-init.zsh"
  local bin=$(command -v "$tool")
  if [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
    mkdir -p "${cache:h}"
    eval "$cmd" > "$cache" 2>/dev/null
  fi
  source "$cache"
}

have zoxide && _lazy_init zoxide "zoxide init --cmd cd zsh"
have fzf && _lazy_init fzf "fzf --zsh"

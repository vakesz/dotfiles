# Zinit Plugin Manager

ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"

# Download Zinit if not already installed
if [[ ! -d "$ZINIT_HOME" ]]; then
  print -P "%F{33}Installing Zinit...%f"
  command mkdir -p "$(dirname "$ZINIT_HOME")"
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

load_cached_init oh-my-posh "oh-my-posh init zsh --config '$XDG_CONFIG_HOME/oh-my-posh/zen.toml'" "$XDG_CONFIG_HOME/oh-my-posh/zen.toml"
load_cached_init zoxide "zoxide init --cmd cd zsh"

if [[ -t 0 && -t 1 ]]; then
  load_cached_init fzf "fzf --zsh"
fi

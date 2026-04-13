# Zinit Plugin Manager

ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  print -P "%F{33}Installing Zinit...%f"
  command mkdir -p "${ZINIT_HOME:h}"
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

if [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "wsl" ]]; then
  export NVM_DIR="${XDG_DATA_HOME}/nvm"

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    load_nvm() {
      unfunction nvm node npm npx load_nvm 2>/dev/null
      source "$NVM_DIR/nvm.sh"
      [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    }

    nvm() { load_nvm && nvm "$@"; }
    node() { load_nvm && node "$@"; }
    npm() { load_nvm && npm "$@"; }
    npx() { load_nvm && npx "$@"; }
  fi
fi

load_tool_init oh-my-posh "oh-my-posh init zsh --config '$XDG_CONFIG_HOME/oh-my-posh/zen.toml'" "$XDG_CONFIG_HOME/oh-my-posh/zen.toml"
load_tool_init zoxide "zoxide init zsh --cmd cd"

if [[ -t 0 && -t 1 ]]; then
  load_tool_init fzf "fzf --zsh"
fi

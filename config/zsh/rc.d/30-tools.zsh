# Zinit Plugin Manager

ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"

if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"

  zinit light-mode lucid for \
      zsh-users/zsh-autosuggestions

  zinit wait'0a' lucid for \
      zsh-users/zsh-syntax-highlighting
else
  if [[ -z "${DOTFILES_ZINIT_WARNING_SHOWN:-}" ]]; then
    export DOTFILES_ZINIT_WARNING_SHOWN=1
    print -P "%F{33}Zinit is not installed; skipping zinit-managed plugins.%f" >&2
    print -P "%F{33}Install it with: git clone --depth=1 https://github.com/zdharma-continuum/zinit.git ${ZINIT_HOME}%f" >&2
  fi
fi

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

# Shell plugins and tool integrations

# Autosuggestions (syntax highlighting is sourced last in 40-completion.zsh
# because it must run after compinit and after autosuggestions).
if [[ -n "${HOMEBREW_PREFIX:-}" \
   && -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Lazy-load NVM on Linux/WSL (macOS uses the Homebrew Node).
if [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "wsl" ]]; then
  export NVM_DIR="$XDG_DATA_HOME/nvm"

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

load_tool_init oh-my-posh "oh-my-posh init zsh --config '$XDG_CONFIG_HOME/oh-my-posh/zen.toml'" "$XDG_CONFIG_HOME/oh-my-posh/zen.toml" "${(%):-%N}"
load_tool_init zoxide "zoxide init zsh --cmd cd" "${(%):-%N}"

if [[ -t 0 && -t 1 ]]; then
  load_tool_init fzf "fzf --zsh" "${(%):-%N}"
fi

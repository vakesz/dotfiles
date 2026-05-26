# Shell plugins and tool integrations

# Autosuggestions (syntax highlighting is sourced last in 40-completion.zsh
# because it must run after compinit and after autosuggestions).
[[ -n "${HOMEBREW_PREFIX:-}" ]] \
  && source_if_readable "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Node runtime/version management via fnm.
load_tool_init fnm "fnm env --shell zsh --use-on-cd" "${(%):-%N}"

load_tool_init starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "${(%):-%N}"

load_tool_init zoxide "zoxide init zsh --cmd cd" "${(%):-%N}"

if [[ -t 0 && -t 1 ]]; then
  load_tool_init fzf "fzf --zsh" "${(%):-%N}"
fi

# Shell plugins and tool integrations

# Autosuggestions (syntax highlighting must load after compinit and autosuggestions)
[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

load_tool_init fnm "fnm env --shell zsh --use-on-cd" "${(%):-%N}"
load_tool_init starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "${(%):-%N}"
load_tool_init zoxide "zoxide init zsh --cmd cd" "${(%):-%N}"
[[ -t 0 && -t 1 ]] && load_tool_init fzf "fzf --zsh" "${(%):-%N}"

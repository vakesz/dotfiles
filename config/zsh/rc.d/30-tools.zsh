# Shell plugins and tool integrations

# Autosuggestions (zsh-syntax-highlighting loads last, in 40-completion.zsh)
[[ -r ${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

load_fnm_init() {
  (( $+commands[fnm] )) || return 0

  path=("${(@)path:#${XDG_STATE_HOME}/fnm_multishells/*/bin}")

  local init
  init="$(fnm env --shell zsh --use-on-cd --corepack-enabled)" || return 0
  eval "$init"
  typeset -U path
}

load_fnm_init
[[ -t 1 && ${TERM:-} != dumb ]] \
  && load_cached_tool_init starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "${(%):-%N}"
load_cached_tool_init zoxide "zoxide init zsh --cmd cd" "${(%):-%N}"
[[ -t 0 && -t 1 ]] && load_cached_tool_init fzf "fzf --zsh" "${(%):-%N}"

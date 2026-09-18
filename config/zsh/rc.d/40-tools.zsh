# Tool integrations (interactive shell plugins live in 90-plugins.zsh)

# Nothing else defines LS_COLORS (ls is aliased to eza), and 50-completion.zsh
# feeds it to the completion list-colors zstyle.
_dotfiles_cache_tool dircolors "dircolors -b" "${(%):-%N}"

if (( $+commands[fnm] )); then
  # Drop the previous shell's multishell dir, which fnm leaves in an inherited PATH.
  path=("${(@)path:#${XDG_STATE_HOME}/fnm_multishells/*/bin}")
  _fnm_env="$(fnm env --shell zsh --use-on-cd --corepack-enabled)" && eval "$_fnm_env"
  unset _fnm_env
fi

[[ -t 1 && ${TERM:-} != dumb ]] \
  && _dotfiles_cache_tool starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "${(%):-%N}"
_dotfiles_cache_tool zoxide "zoxide init zsh --cmd cd" "${(%):-%N}"

# fzf runs FZF_DEFAULT_COMMAND through sh, so the `fd=fdfind` alias never applies.
if (( $+commands[fd] || $+commands[fdfind] )); then
  export FZF_DEFAULT_COMMAND="${commands[fd]:-${commands[fdfind]}} --type f --hidden --follow"
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

[[ -t 0 && -t 1 ]] && _dotfiles_cache_tool fzf "fzf --zsh" "${(%):-%N}"

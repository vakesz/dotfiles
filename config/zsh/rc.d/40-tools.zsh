# Tool integrations (interactive shell plugins live in 90-plugins.zsh)

# Cached init scripts are also regenerated when this file changes.
_dotfiles_tools_rc="${(%):-%N}"

# LS_COLORS drives the completion colors in 50-completion.zsh. On macOS only
# Homebrew coreutils' prefixed gdircolors is available.
if (( $+commands[dircolors] )); then
  _dotfiles_cache_tool dircolors "dircolors -b" "$_dotfiles_tools_rc"
else
  _dotfiles_cache_tool gdircolors "gdircolors -b" "$_dotfiles_tools_rc"
fi

[[ -t 1 && ${TERM:-} != dumb ]] \
  && _dotfiles_cache_tool starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "$_dotfiles_tools_rc"
_dotfiles_cache_tool zoxide "zoxide init zsh --cmd cd" "$_dotfiles_tools_rc"
[[ -t 0 && -t 1 ]] && _dotfiles_cache_tool direnv "direnv hook zsh" "$_dotfiles_tools_rc"

# fzf runs FZF_DEFAULT_COMMAND through sh, where the fd=fdfind alias doesn't exist.
if (( $+commands[fd] || $+commands[fdfind] )); then
  export FZF_DEFAULT_COMMAND="${commands[fd]:-${commands[fdfind]}} --type f --hidden --follow"
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

[[ -t 0 && -t 1 ]] && _dotfiles_cache_tool fzf "fzf --zsh" "$_dotfiles_tools_rc"

unset _dotfiles_tools_rc

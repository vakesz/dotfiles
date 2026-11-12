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

# Starship logs under $XDG_CACHE_HOME/starship and complains at every prompt
# when it can't, so point it at a private writable dir in that case.
if [[ -z ${STARSHIP_CACHE:-} ]] && ! _dotfiles_writable_dir "$XDG_CACHE_HOME/starship"; then
  export STARSHIP_CACHE="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/starship-$UID"
fi
[[ -t 1 && ${TERM:-} != dumb ]] \
  && _dotfiles_cache_tool starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "$_dotfiles_tools_rc"
_dotfiles_cache_tool zoxide "zoxide init zsh --cmd cd" "$_dotfiles_tools_rc"
[[ -t 0 && -t 1 ]] && _dotfiles_cache_tool direnv "direnv hook zsh" "$_dotfiles_tools_rc"

# fzf runs FZF_DEFAULT_COMMAND through sh, where the fd=fdfind alias doesn't exist.
# fd reads $XDG_CONFIG_HOME/fd/ignore automatically, so no --ignore-file needed.
if (( $+commands[fd] || $+commands[fdfind] )); then
  export FZF_DEFAULT_COMMAND="${commands[fd]:-${commands[fdfind]}} --type f --hidden --follow"
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

# `fzf --zsh` needs fzf 0.48+. Older distro builds (Ubuntu 24.04 ships 0.44)
# fall back to the packaged scripts. The fallback always prints something, so
# the cache is kept until fzf itself changes instead of failing every start.
_dotfiles_fzf_files=(
  /usr/share/doc/fzf/examples/{key-bindings,completion}.zsh(N)  # Debian/Ubuntu
  /usr/share/fzf/{key-bindings,completion}.zsh(N)               # Arch
  /usr/share/fzf/shell/key-bindings.zsh(N)                      # Fedora
)
_dotfiles_fzf_distro_init() {
  print -r -- '# fzf: packaged shell integration'
  (( $#_dotfiles_fzf_files )) && command cat -- "${_dotfiles_fzf_files[@]}"
  return 0
}
[[ -t 0 && -t 1 ]] && _dotfiles_cache_tool fzf \
  "fzf --zsh 2>/dev/null || _dotfiles_fzf_distro_init" \
  "$_dotfiles_tools_rc" "${_dotfiles_fzf_files[@]}"
unfunction _dotfiles_fzf_distro_init
unset _dotfiles_fzf_files _dotfiles_tools_rc

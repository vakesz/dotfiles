# Tool integrations (interactive shell plugins live in 90-plugins.zsh)

# gpg-agent's pinentry needs to know which terminal to prompt on.
[[ -t 0 ]] && export GPG_TTY="$TTY"
# A default, not forced: terminals that know better set it themselves, and
# ssh doesn't forward it, so remote shells would otherwise lose truecolor.
export COLORTERM="${COLORTERM:-truecolor}"

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
# starship's init computes PROMPT2 with `starship prompt --continuation` at
# every start. The value only depends on the config, so bake it into the
# cache. Without STARSHIP_SHELL, starship leaves out zsh's %{ %} wrappers.
_dotfiles_starship_init() {
  local init continuation
  init="$(starship init zsh)" || return
  continuation="$(STARSHIP_SHELL=zsh starship prompt --continuation)" || return
  print -rl -- "${(@)${(@f)init}:#PROMPT2=*}" "PROMPT2=${(qq)continuation}"
}
[[ -t 1 && ${TERM:-} != dumb ]] \
  && _dotfiles_cache_tool starship _dotfiles_starship_init "$XDG_CONFIG_HOME/starship.toml" "$_dotfiles_tools_rc"
unfunction _dotfiles_starship_init
# zoxide loads in 50-completion.zsh, after compinit.
[[ -t 0 && -t 1 ]] && _dotfiles_cache_tool direnv "direnv hook zsh" "$_dotfiles_tools_rc"

# fzf runs FZF_DEFAULT_COMMAND through sh, where the fd=fdfind alias doesn't exist.
# fd reads $XDG_CONFIG_HOME/fd/ignore automatically, so no --ignore-file needed.
# fzf 0.48+ walks the tree itself for Ctrl-T and Alt-C unless their commands
# are set, and that walker doesn't know fd's ignore list.
if (( $+commands[fd] || $+commands[fdfind] )); then
  _dotfiles_fd="${commands[fd]:-${commands[fdfind]}} --hidden --follow"
  export FZF_DEFAULT_COMMAND="$_dotfiles_fd --type f"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_dotfiles_fd --type d"
  unset _dotfiles_fd
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

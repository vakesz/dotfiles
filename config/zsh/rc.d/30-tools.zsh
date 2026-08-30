# Tool integrations (interactive shell plugins live in 80-plugins.zsh)

load_fnm_init() {
  (( $+commands[fnm] )) || return 0

  path=("${(@)path:#${XDG_STATE_HOME}/fnm_multishells/*/bin}")

  local init
  init="$(fnm env --shell zsh --use-on-cd --corepack-enabled)" || return 0
  eval "$init"
  typeset -U path
}

# LS_COLORS, which 40-completion.zsh feeds to the completion list-colors zstyle.
# Nothing else defines it (ls is aliased to eza, which uses its own palette), so
# without this the completion menu renders with no colour at all.
load_cached_tool_init dircolors "dircolors -b" "${(%):-%N}"

load_fnm_init
[[ -t 1 && ${TERM:-} != dumb ]] \
  && load_cached_tool_init starship "starship init zsh" "$XDG_CONFIG_HOME/starship.toml" "${(%):-%N}"
load_cached_tool_init zoxide "zoxide init zsh --cmd cd" "${(%):-%N}"
[[ -t 0 && -t 1 ]] && load_cached_tool_init fzf "fzf --zsh" "${(%):-%N}"

# ripgrep + fzf: fuzzy search file contents, open the match in $EDITOR at that line.
if (( $+commands[rg] && $+commands[fzf] )); then
  rgf() {
    local selection file line
    local separator=$'\x1f'
    local -a fzf_options=(--ansi --delimiter="$separator")

    if (( $+commands[bat] )); then
      fzf_options+=(--preview 'bat --color=always --highlight-line {2} {1}')
    fi

    selection="$(
      rg \
        --with-filename \
        --line-number \
        --no-heading \
        --color=always \
        --field-match-separator='\x1f' \
        "$@" |
        fzf "${fzf_options[@]}"
    )" || return
    [[ -z "$selection" ]] && return

    file="${selection%%${separator}*}"
    line="${selection#*${separator}}"
    line="${line%%${separator}*}"
    "${EDITOR:-vi}" "+$line" "$file"
  }
fi

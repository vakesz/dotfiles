# Interactive commands and aliases

# Measure interactive startup time over N login shells, defaulting to ten.
zsh-profile() {
  local runs="${1:-10}" i
  for (( i = 1; i <= runs; i++ )); do
    /usr/bin/time zsh -lic exit
  done
}

# Navigation
alias dots='cd ~/.dotfiles'
alias c='cd ~/Code'

# Git
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias ga='git add'
alias gp='git push'

# Everything below depends on an optional tool being installed.

# Search file contents with ripgrep, pick a match with fzf, open it at that line.
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

# fd and bat are packaged as fdfind and batcat on Debian/Ubuntu.
(( $+commands[fdfind] )) && alias fd=fdfind
(( $+commands[batcat] )) && alias bat='batcat'
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat --paging=never'

if (( $+commands[uv] )); then
  alias uv-tools='uv tool list'
  alias uv-python='uv python list'
fi

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias l='eza --oneline --group-directories-first'
  alias lt='eza --tree --level=2'
else
  # --version rather than --color=auto: BSD ls rejects it and neither lists $PWD.
  if ls --version >/dev/null 2>&1; then
    alias ls='ls --color=auto'
  else
    alias ls='ls -G'
  fi
  alias ll='ls -la'
  alias la='ls -A'
  alias l='ls -CF'
fi

(( $+commands[docker] )) && {
  alias dcu='docker compose up'
  alias dcd='docker compose down'
}

(( $+commands[claude] )) && alias cc='claude'
(( $+commands[codex] )) && alias cx='codex'
(( $+commands[opencode] )) && alias oc='opencode'

# Interactive commands and aliases

# Search file contents with ripgrep, pick a match with fzf, and open it at the
# selected line in the configured editor.
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

# Measure interactive startup time over N login shells, defaulting to ten.
zsh-profile() {
  local runs="${1:-10}" i
  for (( i = 1; i <= runs; i++ )); do
    /usr/bin/time zsh -lic exit
  done
}

(( $+commands[fdfind] )) && alias fd=fdfind

if (( $+commands[uv] )); then
  alias uv-tools='uv tool list'
  alias uv-python='uv python list'
fi

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2'
else
  if ls --color=auto &>/dev/null; then
    alias ls='ls --color=auto'
  else
    alias ls='ls -G'
  fi
  alias ll='ls -la'
  alias la='ls -A'
  alias l='ls -CF'
fi

# bat is packaged as `batcat` on Debian/Ubuntu.
(( $+commands[batcat] )) && alias bat='batcat'
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat --paging=never'

# Navigation
alias dots='cd ~/.dotfiles'
alias c='cd ~/Code'

# Git
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias ga='git add'
alias gp='git push'

(( $+commands[docker] )) && {
  alias dcu='docker compose up'
  alias dcd='docker compose down'
}

# AI tools
(( $+commands[claude] )) && alias cc='claude'
(( $+commands[opencode] )) && alias oc='opencode'

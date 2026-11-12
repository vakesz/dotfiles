# Completion

export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

# Homebrew's completions are already on fpath: brew shellenv (20-path.zsh) adds them.

if ! (( ${+_comps} )); then
  zmodload zsh/complist 2>/dev/null || true
  autoload -Uz compinit
  # Skip the slow security check if the dump is less than a day old. Without
  # a writable cache, -D skips the dump instead of failing to write it.
  if ! _dotfiles_writable_dir "${ZSH_COMPDUMP:h}"; then
    compinit -D
  elif [[ -n ${ZSH_COMPDUMP}(#qN.mh-24) ]]; then
    compinit -C -d "$ZSH_COMPDUMP"
  else
    compinit -d "$ZSH_COMPDUMP"
  fi

  _dotfiles_zcompile "$ZSH_COMPDUMP"
fi

setopt ALWAYS_TO_END
setopt AUTO_PARAM_SLASH
setopt COMPLETE_IN_WORD
setopt LIST_PACKED
setopt MENU_COMPLETE

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
# Unquoted so an empty LS_COLORS adds no arguments. 40-tools.zsh sets it.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Offer . and .., which cd and git subcommands need.
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true
# Completion caching writes on first use, so only enable it when it can.
if _dotfiles_writable_dir "$XDG_CACHE_HOME/zsh"; then
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/completion-cache"
fi
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{magenta}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

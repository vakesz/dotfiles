# Completion

export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

# The only source of site-functions on Linuxbrew, where brew shellenv never runs.
if (( $+commands[brew] )) && [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

if ! (( ${+_comps} )); then
  zmodload zsh/complist 2>/dev/null || true
  autoload -Uz compinit
  mkdir -p "${ZSH_COMPDUMP:h}"
  # Skip the slow security audit if the dump is fresh (<24h).
  if [[ -n ${ZSH_COMPDUMP}(#qN.mh-24) ]]; then
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
# Unquoted so an empty LS_COLORS yields no arguments; 40-tools.zsh must set it first.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Offer . and .. where they are valid, which cd and the git subcommands need.
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/completion-cache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

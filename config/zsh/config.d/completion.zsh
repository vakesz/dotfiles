# Completion Configuration

# Homebrew completions (docker, docker-compose, docker-buildx, etc.)
if (( $+commands[brew] )); then
  local brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
  fpath=("$brew_prefix/share/zsh/site-functions" $fpath)
fi

if ! (( ${+_comps} )); then
  autoload -Uz compinit
  ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"

  # Only regenerate compdump once a day
  if [[ -n ${ZSH_COMPDUMP}(#qN.mh+24) ]]; then
    compinit -d "$ZSH_COMPDUMP"
  else
    compinit -C -d "$ZSH_COMPDUMP"
  fi
fi

# Zsh Options
setopt ALWAYS_TO_END          # Move cursor to end of word after completion
setopt AUTO_MENU              # Show completion menu on successive tab press
setopt AUTO_PARAM_SLASH       # Add trailing slash to directory completions
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt LIST_PACKED            # Make completion list smaller
setopt MENU_COMPLETE          # Auto-select first completion entry
unsetopt FLOW_CONTROL         # Disable flow control (Ctrl-S/Ctrl-Q)

setopt AUTO_CD                # Type directory name to cd into it
setopt AUTO_PUSHD             # Push old directory onto stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates
setopt PUSHD_SILENT           # Don't print stack after pushd/popd

setopt EXTENDED_GLOB          # Extended glob patterns (#, ~, ^)
setopt GLOB_DOTS              # Include dotfiles in globs

setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell

# Completion Styling
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion-cache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# History search with arrow keys
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # Up arrow
bindkey '^[[B' down-line-or-beginning-search  # Down arrow

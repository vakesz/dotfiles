# Description: Zsh completion system configuration
# Load order: Late (after most other configurations)

# ============================================================================
# Completions Setup
# ============================================================================
autoload -Uz compinit

# Only regenerate compdump once a day for faster startup
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Completion styling
setopt AUTO_LIST              # Automatically list choices on ambiguous completion
setopt AUTO_MENU              # Use menu completion after second tab press
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt ALWAYS_TO_END          # Move cursor to end if word had one match

# Better completion matching (case-insensitive, partial matching)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

# Cache completions for faster loading
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

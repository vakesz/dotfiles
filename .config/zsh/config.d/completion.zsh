# ============================================================================
# Completion Configuration
# ============================================================================
# Zsh completion system settings and customization

# ----------------------------------------------------------------------------
# Completion System Initialization
# ----------------------------------------------------------------------------

# Load and initialize the completion system
autoload -Uz compinit

# Only regenerate compdump once a day for faster startup
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ----------------------------------------------------------------------------
# Completion Options
# ----------------------------------------------------------------------------

setopt ALWAYS_TO_END          # Move cursor to end of word after completion
setopt AUTO_MENU              # Show completion menu on successive tab press
setopt AUTO_PARAM_SLASH       # Add trailing slash to directory completions
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt LIST_PACKED            # Make completion list smaller
setopt MENU_COMPLETE          # Auto-select first completion entry

unsetopt FLOW_CONTROL         # Disable flow control (Ctrl-S/Ctrl-Q)

# ----------------------------------------------------------------------------
# Completion Styling
# ----------------------------------------------------------------------------

# Case-insensitive, partial-word, and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Use colors in completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Menu selection
zstyle ':completion:*:*:*:*:*' menu select

# Complete processes for kill command
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
  clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
  gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
  ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
  operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
  usbmux uucp vcsa wwwrun xfs '_*'

# Ignore completion for commands we don't have
zstyle ':completion:*:functions' ignored-patterns '_*'

# Directory completion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion-cache"

# Group results by category
zstyle ':completion:*' group-name ''

# Descriptions for different completion types
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# ----------------------------------------------------------------------------
# History-Based Completion
# ----------------------------------------------------------------------------

setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries from history
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from history items
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt SHARE_HISTORY          # Share history between all sessions
setopt APPEND_HISTORY         # Append to history file
setopt INC_APPEND_HISTORY     # Write to history file immediately
setopt HIST_FIND_NO_DUPS      # Don't show duplicates when searching
setopt HIST_SAVE_NO_DUPS      # Don't write duplicates to history file

# ----------------------------------------------------------------------------
# FZF-Tab Configuration
# ----------------------------------------------------------------------------

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Preview directory's content with lsd when completing cd
if have lsd; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --color=always $realpath'
elif have ls; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
fi

# Switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

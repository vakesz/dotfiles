# Interactive shell options and history

# Select vi mode before fzf initializes in 40-tools.zsh: fzf binds Tab into the
# current keymap, so switching modes afterwards would drop its completion.
bindkey -v

# Hundredths of a second; 1 removes the default 0.4s delay after Escape.
KEYTIMEOUT=1

unsetopt FLOW_CONTROL
unsetopt BEEP
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS

# Drop / and - so word-wise editing stops at path segments and flags.
WORDCHARS="${WORDCHARS//[\/-]/}"

# HISTSIZE exceeds SAVEHIST so duplicate expiry can preserve unique entries.
HISTSIZE=120000
SAVEHIST=100000
HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "${HISTFILE:h}"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt HIST_NO_STORE
setopt HIST_FCNTL_LOCK

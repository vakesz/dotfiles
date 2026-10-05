# Interactive shell options and history

# Pick vi mode before 40-tools.zsh loads fzf. fzf binds Tab in the current
# keymap, so switching keymaps afterwards would lose its completion.
bindkey -v

# In hundredths of a second. Removes the default 0.4s delay after Escape.
KEYTIMEOUT=1

unsetopt FLOW_CONTROL
unsetopt BEEP
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS

# Remove / and - so word motions stop at path segments and flags.
WORDCHARS="${WORDCHARS//[\/-]/}"

HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "${HISTFILE:h}"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
# Lines shared from other sessions can still repeat in searches.
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt HIST_SAVE_NO_DUPS
setopt HIST_NO_STORE
setopt HIST_FCNTL_LOCK

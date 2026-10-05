# Keybindings layered on the vi keymap selected in 30-options.zsh

# Every binding names its keymap: plain bindkey only changes the current one,
# which in vi mode is insert mode.

# Search history for lines starting with what's already typed.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# viins maps ^? to vi-backward-delete-char, which won't delete past the point
# where insert mode started.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line

# terminfo has the keys this terminal sends. The literal sequences cover
# terminals without terminfo entries and multiplexers in application-cursor mode.
for keymap in viins vicmd; do
  bindkey -M "$keymap" '^[[A' up-line-or-beginning-search
  bindkey -M "$keymap" '^[[B' down-line-or-beginning-search
  bindkey -M "$keymap" "${terminfo[khome]:-$'\e[H'}" beginning-of-line
  bindkey -M "$keymap" "${terminfo[kend]:-$'\e[F'}" end-of-line
  bindkey -M "$keymap" "${terminfo[kdch1]:-$'\e[3~'}" delete-char
  bindkey -M "$keymap" $'\e[1~' beginning-of-line
  bindkey -M "$keymap" $'\e[4~' end-of-line
  bindkey -M "$keymap" $'\eOH' beginning-of-line
  bindkey -M "$keymap" $'\eOF' end-of-line
  bindkey -M "$keymap" $'\e[1;5C' forward-word   # Ctrl-Right
  bindkey -M "$keymap" $'\e[1;5D' backward-word  # Ctrl-Left
  bindkey -M "$keymap" $'\e[1;3C' forward-word   # Alt-Right
  bindkey -M "$keymap" $'\e[1;3D' backward-word  # Alt-Left
done
unset keymap

# `v` in normal mode opens the current command line in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# vi text objects such as ci" and da( on the command line.
autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
for keymap in viopp visual; do
  for object in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M "$keymap" "$object" select-bracketed
  done
  for object in {a,i}${(s..)^:-\'\"\`}; do
    bindkey -M "$keymap" "$object" select-quoted
  done
done
unset keymap object

# Block cursor in normal mode, bar in insert.
_dotfiles_set_cursor_shape() {
  case "${KEYMAP:-viins}" in
    vicmd) print -n '\e[2 q' ;;
    *)     print -n '\e[6 q' ;;
  esac
}

_dotfiles_zle_line_init() {
  # Start every prompt in insert mode.
  zle -K viins
  _dotfiles_set_cursor_shape
}

# Restore the block cursor for the command about to run.
_dotfiles_zle_line_finish() { print -n '\e[2 q' }

zle -N zle-keymap-select _dotfiles_set_cursor_shape
zle -N zle-line-init _dotfiles_zle_line_init
zle -N zle-line-finish _dotfiles_zle_line_finish

# Keybindings layered on the vi keymap selected in 30-options.zsh

# Bindings name their keymap: an unqualified bindkey only touches the current
# keymap, which in a vi setup means insert mode alone.

# History search that respects the text already typed before the cursor.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# viins leaves ^? on vi-backward-delete-char, which refuses to delete past the
# point where insert mode began.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line

# terminfo carries what this terminal sends; the literal sequences cover
# terminals that report nothing and the application-cursor mode multiplexers use.
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

# Text objects, so ci" and da( work on the command line the way they do in vi.
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
  # Start every prompt in insert mode, whatever mode the last line left.
  zle -K viins
  _dotfiles_set_cursor_shape
}

# Leave a normal block cursor behind for whatever command runs next.
_dotfiles_zle_line_finish() { print -n '\e[2 q' }

zle -N zle-keymap-select _dotfiles_set_cursor_shape
zle -N zle-line-init _dotfiles_zle_line_init
zle -N zle-line-finish _dotfiles_zle_line_finish

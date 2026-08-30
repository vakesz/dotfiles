# Keybindings
#
# The vi keymap itself is selected in 10-env.zsh, which has to run before fzf's
# init in 30-tools.zsh. Everything here layers on top of it.
#
# Bindings name their keymap explicitly. An unqualified bindkey only touches
# whichever keymap is current, which in a vi setup silently means "insert mode
# only" — half the bindings would go missing in normal mode.

# History search that respects the text already typed before the cursor.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
# k and j do the same search from normal mode.
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# Insert-mode editing that vi mode does not provide on its own.
#
# The important one is backspace: viins leaves ^? bound to
# vi-backward-delete-char, which refuses to delete past the point where insert
# mode began, so backspace stops dead when editing a recalled history line.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line

# Home / End / Delete and word-wise motion, in both modes. terminfo carries what
# the running terminal actually sends; the literal sequences cover terminals
# that report nothing useful and the application-cursor mode some multiplexers
# leave the keypad in. WORDCHARS in 10-env.zsh drops / and - so the word motions
# stop at each path segment and each flag.
_dotfiles_bind_shared_keys() {
  local keymap
  for keymap in viins vicmd; do
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
}
_dotfiles_bind_shared_keys
unfunction _dotfiles_bind_shared_keys

# `v` in normal mode opens the current command line in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Text objects, so ci" and da( work on the command line the way they do in vi.
autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
_dotfiles_bind_text_objects() {
  local keymap object
  for keymap in viopp visual; do
    for object in {a,i}${(s..)^:-'()[]{}<>bB'}; do
      bindkey -M "$keymap" "$object" select-bracketed
    done
    for object in {a,i}${(s..)^:-\'\"\`}; do
      bindkey -M "$keymap" "$object" select-quoted
    done
  done
}
_dotfiles_bind_text_objects
unfunction _dotfiles_bind_text_objects

# Show which mode is active: a block cursor in normal mode, a bar in insert.
# Without this the only way to tell them apart is to type and find out.
_dotfiles_set_cursor_shape() {
  case "${KEYMAP:-viins}" in
    vicmd) print -n '\e[2 q' ;;   # steady block
    *)     print -n '\e[6 q' ;;   # steady bar
  esac
}

_dotfiles_zle_keymap_select() { _dotfiles_set_cursor_shape }

_dotfiles_zle_line_init() {
  # Always start a new prompt in insert mode, whatever mode the last line left.
  zle -K viins
  _dotfiles_set_cursor_shape
}

# Leave a normal block cursor behind for whatever command runs next.
_dotfiles_zle_line_finish() { print -n '\e[2 q' }

zle -N zle-keymap-select _dotfiles_zle_keymap_select
zle -N zle-line-init _dotfiles_zle_line_init
zle -N zle-line-finish _dotfiles_zle_line_finish

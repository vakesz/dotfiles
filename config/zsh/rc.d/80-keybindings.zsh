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

# Bind every form a key can arrive in. terminfo's arrow, Home and End keys are
# the application-mode ones (\eOA, \eOH), but zle never turns that mode on, so
# most terminals send the \e[ forms. Multiplexers and some terminals send the
# \eO forms anyway, and \e[1~ and \e[4~ come from tmux and the Linux console.
_dotfiles_bind() {
  local widget="$1" keymap key
  shift
  for keymap in viins vicmd; do
    for key in "$@"; do
      [[ -n "$key" ]] && bindkey -M "$keymap" "$key" "$widget"
    done
  done
  return 0
}
_dotfiles_bind up-line-or-beginning-search $'\e[A' $'\eOA'
_dotfiles_bind down-line-or-beginning-search $'\e[B' $'\eOB'
_dotfiles_bind beginning-of-line "${terminfo[khome]}" $'\e[H' $'\eOH' $'\e[1~'
_dotfiles_bind end-of-line "${terminfo[kend]}" $'\e[F' $'\eOF' $'\e[4~'
_dotfiles_bind delete-char "${terminfo[kdch1]}" $'\e[3~'
_dotfiles_bind forward-word $'\e[1;5C' $'\e[1;3C'   # Ctrl-Right, Alt-Right
_dotfiles_bind backward-word $'\e[1;5D' $'\e[1;3D'  # Ctrl-Left, Alt-Left
unfunction _dotfiles_bind

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

# Block cursor in normal mode, bar in insert. Skipped when stdout isn't a
# tty or TERM is dumb, where the escape codes would print as garbage.
_dotfiles_set_cursor_shape() {
  [[ -t 1 && ${TERM:-} != dumb ]] || return 0
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
_dotfiles_zle_line_finish() {
  [[ -t 1 && ${TERM:-} != dumb ]] || return 0
  print -n '\e[2 q'
}

# add-zle-hook-widget keeps widgets already on these hooks, such as the
# keymap-select one starship's init installs to redraw its vi-mode symbol.
autoload -Uz add-zle-hook-widget
add-zle-hook-widget keymap-select _dotfiles_set_cursor_shape
add-zle-hook-widget line-init _dotfiles_zle_line_init
add-zle-hook-widget line-finish _dotfiles_zle_line_finish

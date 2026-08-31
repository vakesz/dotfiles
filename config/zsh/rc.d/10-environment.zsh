# Interactive environment

typeset -U path

typeset -g OS_TYPE="unknown"
case "$OSTYPE" in
  darwin*) OS_TYPE="macos" ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS_TYPE="wsl"
    else
      OS_TYPE="linux"
    fi
    ;;
esac

export LANG="en_US.UTF-8"
export COLORTERM="truecolor"

export EDITOR="vi"
export VISUAL="vi"

[[ -t 0 ]] && export GPG_TTY="$TTY"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

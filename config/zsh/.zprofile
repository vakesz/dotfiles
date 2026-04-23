# Login shell setup

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" \
  "${XDG_STATE_HOME}/zsh" "${XDG_CACHE_HOME}/zsh"

# Ensures GUI apps launched from Finder have the Homebrew-aware PATH.
if [[ "$OSTYPE" == darwin* && -f /usr/libexec/path_helper ]]; then
  eval "$(/usr/libexec/path_helper -s)"
fi

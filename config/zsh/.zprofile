# .zprofile - Login shell setup

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" 2>/dev/null
mkdir -p "${XDG_STATE_HOME}/zsh" "${XDG_CACHE_HOME}/zsh" "${XDG_DATA_HOME}/zinit" 2>/dev/null

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Ensures GUI apps launched from Finder have correct PATH
  if [[ -f /usr/libexec/path_helper ]]; then
    eval "$(/usr/libexec/path_helper -s)"
  fi

  # Prevents .zsh_sessions from cluttering $ZDOTDIR
  export SHELL_SESSIONS_DISABLE=1
fi

# Login shell setup

# Ensures GUI apps launched from Finder have the Homebrew-aware PATH.
if [[ "$OSTYPE" == darwin* && -f /usr/libexec/path_helper ]]; then
  eval "$(/usr/libexec/path_helper -s)"
fi

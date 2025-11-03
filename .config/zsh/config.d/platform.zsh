# ============================================================================
# Platform Detection
# ============================================================================
# Detects the operating system and sets OS_TYPE variable
# Values: macos, linux, wsl, unknown

case "$OSTYPE" in
  darwin*)
    export OS_TYPE="macos"
    ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      export OS_TYPE="wsl"
    else
      export OS_TYPE="linux"
    fi
    ;;
  *)
    export OS_TYPE="unknown"
    ;;
esac

# Helper function to check if command exists
have() {
  command -v "$1" >/dev/null 2>&1
}

# Helper function to create alias only if command exists
alias_if_exists() {
  have "$2" && alias "$1"="$3"
}

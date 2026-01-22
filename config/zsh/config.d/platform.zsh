# Platform Detection (sets OS_TYPE: macos, linux, wsl, unknown)

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

have() {
  command -v "$1" >/dev/null 2>&1
}

alias_if_exists() {
  have "$2" && alias "$1=$3"
}

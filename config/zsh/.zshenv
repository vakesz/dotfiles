# Environment for every zsh: top-level shells reach it through ~/.zshenv,
# nested shells read it directly because they inherit ZDOTDIR.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
# $UID is a zsh builtin, so this costs no fork.
if [[ "$OSTYPE" == linux* && -z "${XDG_RUNTIME_DIR:-}" && -d "/run/user/$UID" ]]; then
  export XDG_RUNTIME_DIR="/run/user/$UID"
fi

# Keep an inherited value so nested shells and test runs stay on their config.
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

export LANG="${LANG:-en_US.UTF-8}"

# Debian/Ubuntu's /etc/zsh/zshrc would run its own compinit before ours and dump into $ZDOTDIR.
skip_global_compinit=1

# Tool config and cache locations, needed by non-interactive shells too.
export LESS='-R -i -M -W -x4 -F -X'
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/gem"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"

# Toolchain locations. Interactive PATH additions live in rc.d/20-path.zsh.
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_TOOL_DIR="$XDG_DATA_HOME/uv/tools"
export UV_TOOL_BIN_DIR="$XDG_DATA_HOME/uv/bin"
export UV_PYTHON_INSTALL_DIR="$XDG_DATA_HOME/uv/python"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export CCACHE_DIR="$XDG_CACHE_HOME/ccache"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export AZURE_CONFIG_DIR="$XDG_DATA_HOME/azure"
export AZURE_DEVOPS_CACHE_DIR="$XDG_CACHE_HOME/azure-devops"
export CP_HOME_DIR="$XDG_CACHE_HOME/cocoapods"
export NPM_CONFIG_LOGS_DIR="$XDG_STATE_HOME/npm/logs"
export COPILOT_HOME="$XDG_DATA_HOME/copilot"
export __UNSAFE_EXPO_HOME_DIRECTORY="$XDG_DATA_HOME/expo"
export KUBECONFIG="$XDG_CONFIG_HOME/kube/config"
export KUBECACHEDIR="$XDG_CACHE_HOME/kube"

# Gradle and the Android tools need JAVA_HOME, and the Android Gradle Plugin
# needs JDK 17. java_home fails if no matching JDK is installed.
if [[ "$OSTYPE" == darwin* && -z "${JAVA_HOME:-}" && -x /usr/libexec/java_home ]]; then
  if _java_home="$(/usr/libexec/java_home -v 17 2>/dev/null)"; then
    export JAVA_HOME="$_java_home"
  fi
  unset _java_home
fi

# Set here so non-interactive builds (Gradle, React Native CLI) find the SDK.
if [[ "$OSTYPE" == darwin* ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
else
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
fi
# AVDs and emulator snapshots are data, not config.
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export ANDROID_EMULATOR_HOME="$ANDROID_USER_HOME"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"

[[ "$OSTYPE" == linux* ]] && export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

# A function so .zprofile can re-apply it after the system profile resets PATH.
_dotfiles_base_path() {
  local dir
  local -a brew_prefixes
  # pnpm 11 won't run unless its global bin dir is on PATH, even before it exists.
  path=("$PNPM_HOME/bin" "$CARGO_HOME/bin" "${path[@]}")
  # Non-login `zsh -c` shells skip the system profile, so add Homebrew here.
  # Its rustup wrappers come before both Homebrew's bin and $CARGO_HOME/bin
  # (which holds cargo-installed binaries), so non-interactive shells get the
  # brew-managed cargo and rustc without relying on rustup proxies.
  # Only probe this OS's prefixes: /home is an automount on macOS, and testing
  # a path under it stalls every shell start.
  case "$OSTYPE" in
    darwin*) brew_prefixes=(/usr/local /opt/homebrew) ;;
    linux*)  brew_prefixes=(/home/linuxbrew/.linuxbrew "$HOME/.linuxbrew") ;;
  esac
  for dir in "${brew_prefixes[@]}"; do
    [[ -x "$dir/bin/brew" ]] || continue
    path=("$dir/bin" "$dir/sbin" "${path[@]}")
    [[ -d "$dir/opt/rustup/bin" ]] && path=("$dir/opt/rustup/bin" "${path[@]}")
  done
  for dir in "$ANDROID_HOME"/{platform-tools,emulator,cmdline-tools/latest/bin}; do
    [[ -d "$dir" ]] && path=("$dir" "${path[@]}")
  done
  return 0
}

typeset -U path
_dotfiles_base_path
# Not redundant: a shell started with an empty environment (env -i) has PATH
# unexported, so its children would get none. The flag sticks once set.
export PATH

# Stop macOS from writing .zsh_sessions into $ZDOTDIR.
[[ "$OSTYPE" == darwin* ]] && export SHELL_SESSIONS_DISABLE=1

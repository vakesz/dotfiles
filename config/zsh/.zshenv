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

export LANG="${LANG:-en_US.UTF-8}"

# Forced rather than defaulted: launchd-env.zsh copies these into launchd and
# runs with launchd's environment, so a default would keep a stale value.
export EDITOR="vi"
export VISUAL="vi"

# No analytics, no background auto-update (brew and topgrade update
# explicitly), no env hints in brew's output.
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

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

# Toolchain locations. Their bin dirs go on PATH in _dotfiles_base_path below.
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

# Homebrew, in place of a cached `brew shellenv`: the first prefix found wins.
# Its PATH entries are added in _dotfiles_base_path, its completions in
# rc.d/50-completion.zsh. MANPATH needs nothing, since man finds pages through
# PATH. Only probe this OS's prefixes: /home is an automount on macOS, and
# testing a path under it stalls every shell start.
case "$OSTYPE" in
  darwin*) _dotfiles_brew_prefixes=(/opt/homebrew /usr/local) ;;
  linux*)  _dotfiles_brew_prefixes=(/home/linuxbrew/.linuxbrew "$HOME/.linuxbrew") ;;
  *)       _dotfiles_brew_prefixes=() ;;
esac
for _dotfiles_brew_prefix in "${_dotfiles_brew_prefixes[@]}"; do
  [[ -x "$_dotfiles_brew_prefix/bin/brew" ]] || continue
  export HOMEBREW_PREFIX="$_dotfiles_brew_prefix"
  export HOMEBREW_CELLAR="$_dotfiles_brew_prefix/Cellar"
  # bin/brew links into the repository where it isn't the prefix itself
  # (/usr/local/Homebrew on Intel). :A resolves the link without a fork.
  export HOMEBREW_REPOSITORY="${${:-$_dotfiles_brew_prefix/bin/brew}:A:h:h}"
  break
done
unset _dotfiles_brew_prefix _dotfiles_brew_prefixes

# Gradle and the Android tools need JAVA_HOME, and the Android Gradle Plugin
# needs JDK 17. java_home costs about 12ms, so look in the JDK folders first
# (reverse numeric name order, so a vendor's newest 17.x wins), then Homebrew's
# keg-only openjdk@17, which java_home can't see. java_home is the fallback,
# and fails if no matching JDK is installed.
if [[ "$OSTYPE" == darwin* && -z "${JAVA_HOME:-}" ]]; then
  _dotfiles_jdks=(
    {/Library,"$HOME"/Library}/Java/JavaVirtualMachines/*-17(|[.-]*)/Contents/Home(N-/nOn)
  )
  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    _dotfiles_jdks+=("$HOMEBREW_PREFIX"/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home(N-/))
  fi
  if (( $#_dotfiles_jdks )); then
    export JAVA_HOME="$_dotfiles_jdks[1]"
  elif [[ -x /usr/libexec/java_home ]] \
    && _dotfiles_java_home="$(/usr/libexec/java_home -v 17 2>/dev/null)"; then
    export JAVA_HOME="$_dotfiles_java_home"
  fi
  unset _dotfiles_jdks _dotfiles_java_home
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

# The PATH every shell gets, so Makefiles and git hooks find the same tools as
# the prompt. rc.d/20-path.zsh adds keg-only formulae for interactive shells.
# A function so .zprofile can re-apply it after the system profile resets PATH:
# entries put in front move there, appended ones keep their place (path is -U).
_dotfiles_base_path() {
  local -a tools brew android
  # $XDG_BIN_HOME wins over everything. Homebrew's rustup wrappers come before
  # $CARGO_HOME/bin, which may hold rustup's own proxies, so cargo and rustc
  # stay brew-managed. User-installed tools come before Homebrew.
  tools=("$XDG_BIN_HOME")
  [[ -n "${HOMEBREW_PREFIX:-}" ]] && tools+=("$HOMEBREW_PREFIX/opt/rustup/bin")
  tools+=(
    "$CARGO_HOME/bin" "$UV_TOOL_BIN_DIR" "$GOPATH/bin" "$GEM_HOME/bin"
    "${COMPOSER_HOME:-$XDG_CONFIG_HOME/composer}/vendor/bin"
  )
  [[ -n "${HOMEBREW_PREFIX:-}" ]] && brew=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin")
  [[ "$OSTYPE" == linux* ]] && brew+=(/snap/bin)
  # Appended: platform-tools ships its own sqlite3, which mustn't shadow the system one.
  android=("$ANDROID_HOME"/{platform-tools,emulator,cmdline-tools/latest/bin})
  # Missing dirs are left out, except pnpm's: pnpm 11 won't run unless its
  # global bin dir is on PATH, even before it exists.
  path=(
    ${^tools}(N-/)
    "$PNPM_HOME/bin"
    ${^brew}(N-/)
    "${path[@]}"
    ${^android}(N-/)
  )
}

typeset -U path
_dotfiles_base_path
# Not redundant: a shell started with an empty environment (env -i) has PATH
# unexported, so its children would get none. The flag sticks once set.
export PATH

# Stop macOS from writing .zsh_sessions into $ZDOTDIR.
[[ "$OSTYPE" == darwin* ]] && export SHELL_SESSIONS_DISABLE=1

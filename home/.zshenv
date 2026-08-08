export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Tool config/cache redirects (apply to non-interactive shells too).
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
export GCM_CREDENTIAL_CACHE_DIR="$XDG_CACHE_HOME/git-credential-manager"
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

# Toolchain locations (PATH appends still happen in rc.d/20-path.zsh).
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_TOOL_DIR="$XDG_DATA_HOME/uv/tools"
export UV_TOOL_BIN_DIR="$XDG_DATA_HOME/uv/bin"
export UV_PYTHON_INSTALL_DIR="$XDG_DATA_HOME/uv/python"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export AZURE_CONFIG_DIR="$XDG_DATA_HOME/azure"
export CP_HOME_DIR="$XDG_CACHE_HOME/cocoapods"
export NPM_CONFIG_LOGS_DIR="$XDG_STATE_HOME/npm/logs"

# JDK. Gradle and the Android command-line tools (sdkmanager, avdmanager) need
# JAVA_HOME; the Android Gradle Plugin requires 17. java_home exits non-zero
# when no matching JDK is installed, so only export on success.
if [[ "$OSTYPE" == darwin* ]] && [[ -x /usr/libexec/java_home ]]; then
  if _java_home="$(/usr/libexec/java_home -v 17 2>/dev/null)"; then
    export JAVA_HOME="${JAVA_HOME:-$_java_home}"
  fi
  unset _java_home
fi

# Android SDK. React Native / Gradle read $ANDROID_HOME to locate the SDK and
# adb; setting it here means non-interactive build shells (gradle, RN CLI) find
# it too. The location is the default installed by Android Studio per platform.
if [[ "$OSTYPE" == darwin* ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
else
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
fi
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$XDG_CONFIG_HOME/.android"
export ANDROID_EMULATOR_HOME="$ANDROID_USER_HOME"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"

if [[ "$OSTYPE" == linux* ]]; then
  export GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc"
  export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
fi

# Ensure PNPM_HOME/bin is on PATH for non-interactive subshells too (topgrade,
# make rules, scripts). pnpm 11 uses $PNPM_HOME/bin as the global bin dir and
# refuses to run if it's not in PATH.
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Put the Android SDK tools (adb, emulator, sdkmanager) on PATH for build shells.
for android_bin in \
  "$ANDROID_HOME/platform-tools" \
  "$ANDROID_HOME/emulator" \
  "$ANDROID_HOME/cmdline-tools/latest/bin"; do
  [[ -d "$android_bin" ]] || continue
  case ":$PATH:" in
    *":$android_bin:"*) ;;
    *) export PATH="$android_bin:$PATH" ;;
  esac
done
unset android_bin

# Prevent .zsh_sessions from cluttering $ZDOTDIR on macOS.
[[ "$OSTYPE" == darwin* ]] && export SHELL_SESSIONS_DISABLE=1

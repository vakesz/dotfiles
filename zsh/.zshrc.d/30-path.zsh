# Description: PATH configuration for development tools and languages
# Dependencies: Homebrew (provides $HOMEBREW_PREFIX)
# Load order: Early (before using any development tools)

# ============================================================================
# Path Configuration
# ============================================================================

# Node.js (Homebrew keg-only)
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/node@22/bin/node" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/node@22/bin:$PATH"
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/node@22/lib${LDFLAGS:+ $LDFLAGS}"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/node@22/include${CPPFLAGS:+ $CPPFLAGS}"
fi

# Ruby (Homebrew keg-only)
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/ruby/bin/ruby" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/ruby/lib${LDFLAGS:+ $LDFLAGS}"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/ruby/include${CPPFLAGS:+ $CPPFLAGS}"
    export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/ruby/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi

# Make (Homebrew keg-only)
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/make/libexec/gnubin/make" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/make/libexec/gnubin:$PATH"
fi

# NPM/PNPM/Yarn - Keep global installs in XDG directory
export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# Go
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# Rust/Cargo
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export PATH="$CARGO_HOME/bin:$PATH"

# Python 3.13 (Homebrew keg-only) - Only on macOS
# On Linux, use system Python to avoid issues with missing ensurepip wheels
if [[ "$OSTYPE" == "darwin"* ]] && [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/python@3.13/bin/python3.13" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/python@3.13/bin:$PATH"
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/python@3.13/lib${LDFLAGS:+ $LDFLAGS}"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/python@3.13/include${CPPFLAGS:+ $CPPFLAGS}"
    export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/python@3.13/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi

# Python (pipx global binaries)
export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/pipx/venvs/bin:$PATH"

# Zig
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/bin/zig" ]]; then
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"
fi

# LLVM (Homebrew keg-only) - Useful for clang, clang-format, etc.
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/llvm/bin" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/llvm/bin:$PATH"
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/llvm/lib${LDFLAGS:+ $LDFLAGS}"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/llvm/include${CPPFLAGS:+ $CPPFLAGS}"
fi

# Deno (for peek.nvim and other Deno tools)
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/bin/deno" ]]; then
    export DENO_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
    export PATH="$DENO_INSTALL/bin:$PATH"
fi

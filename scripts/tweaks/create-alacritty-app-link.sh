#!/bin/bash
# Create macOS application bundle for Cargo-installed Alacritty

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"
set_log_context "Alacritty"

# Paths
APP_NAME="Alacritty.app"
APP_DIR="/Applications/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

log_info "Setting up $APP_NAME..."

# Find Alacritty binary
CARGO_BIN=$(which alacritty 2>/dev/null)

if [ -z "$CARGO_BIN" ]; then
    log_error "Alacritty not found in PATH (install it via: cargo install alacritty)"
    exit 1
fi

log_info "Found Alacritty at: $CARGO_BIN"

# Remove existing app if it exists
if [ -d "$APP_DIR" ]; then
    log_info "Removing existing $APP_NAME..."
    rm -rf "$APP_DIR"
fi

# Create app bundle structure
log_info "Creating application bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create a wrapper script that ensures PATH includes cargo bin
# Uses XDG Base Directory specification for cargo location
cat > "$MACOS_DIR/alacritty-wrapper" <<'EOF'
#!/bin/bash
# Set XDG_DATA_HOME if not already set
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# Add cargo bin to PATH (XDG-compliant location)
export PATH="$XDG_DATA_HOME/cargo/bin:$PATH"
EOF

# Append the exec line with the actual cargo bin path
cat >> "$MACOS_DIR/alacritty-wrapper" <<EOF
exec "$CARGO_BIN" "\$@"
EOF

chmod +x "$MACOS_DIR/alacritty-wrapper"

# Create symbolic link to the wrapper
ln -sf "$MACOS_DIR/alacritty-wrapper" "$MACOS_DIR/alacritty"

# Write Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>alacritty</string>
    <key>CFBundleIdentifier</key>
    <string>io.alacritty</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Alacritty</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.11</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>CFBundleIconFile</key>
    <string>alacritty</string>
    <key>LSArchitecturePriority</key>
    <array>
        <string>arm64</string>
        <string>x86_64</string>
    </array>
</dict>
</plist>
EOF

# Try to download and copy the Alacritty icon
log_info "Setting up application icon..."
TEMP_ICON="/tmp/alacritty.icns"

if command -v curl &> /dev/null; then
    log_info "Downloading Alacritty icon..."
    if curl -L "https://raw.githubusercontent.com/alacritty/alacritty/master/extra/osx/Alacritty.app/Contents/Resources/alacritty.icns" -o "$TEMP_ICON" 2>/dev/null; then
        cp "$TEMP_ICON" "$RESOURCES_DIR/alacritty.icns"
        rm "$TEMP_ICON"
        log_success "Icon downloaded successfully"
    else
        log_warning "Could not download icon (will use default terminal icon)"
    fi
else
    log_warning "curl not available, skipping icon download"
fi

# Set proper permissions and register app
chmod -R 755 "$APP_DIR"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR"

log_success "Successfully created $APP_NAME at $APP_DIR"
log_info "To add it to the Dock or open it from Spotlight, search for 'Alacritty'"

#!/bin/bash
# Create macOS application bundle for Cargo-installed Alacritty

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paths
APP_NAME="Alacritty.app"
APP_DIR="/Applications/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo -e "${BLUE}Setting up Alacritty.app...${NC}"

# Find Alacritty binary
CARGO_BIN=$(which alacritty 2>/dev/null)

if [ -z "$CARGO_BIN" ]; then
    echo -e "${RED}Error: Alacritty not found in PATH${NC}"
    echo "Install it with: cargo install alacritty"
    exit 1
fi

echo -e "${GREEN}Found Alacritty at: $CARGO_BIN${NC}"

# Remove existing app if it exists
if [ -d "$APP_DIR" ]; then
    echo "Removing existing $APP_NAME..."
    rm -rf "$APP_DIR"
fi

# Create app bundle structure
echo "Creating application bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create a wrapper script that ensures PATH includes cargo bin
cat > "$MACOS_DIR/alacritty-wrapper" << EOF
#!/bin/bash
export PATH="$HOME/.cargo/bin:$HOME/.local/share/cargo/bin:\$PATH"
exec "$CARGO_BIN" "\$@"
EOF

chmod +x "$MACOS_DIR/alacritty-wrapper"

# Create symbolic link to the wrapper
ln -sf "$MACOS_DIR/alacritty-wrapper" "$MACOS_DIR/alacritty"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
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
echo "Setting up application icon..."
TEMP_ICON="/tmp/alacritty.icns"

if command -v curl &> /dev/null; then
    echo "Downloading Alacritty icon..."
    if curl -L "https://raw.githubusercontent.com/alacritty/alacritty/master/extra/osx/Alacritty.app/Contents/Resources/alacritty.icns" -o "$TEMP_ICON" 2>/dev/null; then
        cp "$TEMP_ICON" "$RESOURCES_DIR/alacritty.icns"
        rm "$TEMP_ICON"
        echo -e "${GREEN}✓ Icon downloaded successfully${NC}"
    else
        echo "Could not download icon (will use default terminal icon)"
    fi
else
    echo "curl not available, skipping icon download"
fi

# Set proper permissions
chmod -R 755 "$APP_DIR"

# Refresh Launch Services to register the new app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR"

echo -e "${GREEN}✓ Successfully created $APP_NAME${NC}"
echo -e "${BLUE}Location: $APP_DIR${NC}"
echo ""
echo "You can now:"
echo "  • Open Alacritty from Spotlight (Cmd+Space)"
echo "  • Add it to your Dock"
echo "  • Set it as default terminal in iTerm2 settings"
echo ""
echo "To make it the default terminal application:"
echo "  1. Go to System Settings → Desktop & Dock"
echo "  2. Scroll down to 'Default web browser' area"
echo "  3. Or use: defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.unix-executable;LSHandlerRoleAll=io.alacritty;}'"

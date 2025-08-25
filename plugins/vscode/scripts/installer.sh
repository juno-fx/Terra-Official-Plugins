#!/bin/bash
set -e

# install curl
apt update
apt install curl -y

INSTALL_DIR="$DESTINATION/vscode-$VERSION"
LAUNCH="$INSTALL_DIR/VSCode-linux-x64/bin/code"
ICON="$INSTALL_DIR/vscode.png"

echo "Installing $VERSION"
echo "Destination $INSTALL_DIR"

curl -L -o "/tmp/vscode-$VERSION.tar.gz" -P /tmp "https://update.code.visualstudio.com/$VERSION/linux-x64/stable"

echo "Extracting vscode..."
mkdir -p "$INSTALL_DIR"
tar xzvf "/tmp/vscode-$VERSION.tar.gz" -C "$INSTALL_DIR/"
chmod -R 555 "$INSTALL_DIR"

echo "Adding right permissions for chrome-sandbox"
chown root:root "$INSTALL_DIR/VSCode-linux/bin/chrome-sandbox"
chmod 4755 "$INSTALL_DIR/VSCode-linux/bin/chrome-sandbox"

echo "Adding desktop files"
# app icon setup
cp -v "${PWD}/assets/vscode.png" "$INSTALL_DIR/"
rm -rfv "$INSTALL_DIR/vscode.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=VScode $VERSION
Comment=VScode IDE
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$INSTALL_DIR"/vscode.desktop

cat "$INSTALL_DIR"/*.desktop
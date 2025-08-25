#!/bin/bash
set -e

# install curl
apt update
apt install curl -y

INSTALL_DIR="$DESTINATION/vscode-$VERSION"
LAUNCH="$INSTALL_DIR/bin/vscode.sh "
ICON="$INSTALL_DIR/vscode.png"

echo "Installing $VERSION"
echo "Destination $INSTALL_DIR"

curl -o "/tmp/vscode-$VERSION.tar.gz" -P /tmp "https://update.code.visualstudio.com/$VERSION/linux-x64/stable"

echo "Extracting vscode..."
mkdir -p "$INSTALL_DIR"
tar xzvf "/tmp/vscode-$VERSION.tar.gz" -C "$DESTINATION/"
chmod -R 555 "$DESTINATION"

echo "Adding desktop files"
# app icon setup
cp -v "${PWD}/assets/vscode.png" "$INSTALL_DIR/"
rm -rfv "$INSTALL_DIR/vscode.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=Pycharm $VERSION
Comment=VScode IDE
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$INSTALL_DIR"/vscode.desktop

cat "$INSTALL_DIR"/*.desktop
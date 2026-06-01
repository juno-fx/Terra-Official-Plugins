#!/bin/bash
set -e

apt update
apt install -y wget

echo "Downloading Obsidian..."
wget -q -O /tmp/obsidian.AppImage "$1"
chmod +x /tmp/obsidian.AppImage

echo "Extracting Obsidian..."
cd /tmp
/tmp/obsidian.AppImage --appimage-extract > /dev/null
cp -r -v ./squashfs-root "$2/"
cd -

cp -v ./obsidian.sh "$2/"
sed -i "s@ROOT_APP@$2@g" "$2/obsidian.sh"
chmod +x "$2/obsidian.sh"

cp "./assets/obsidian.png" "$2/obsidian.png"
cp "./assets/obsidian.desktop" "$2/obsidian.desktop"
sed -i -e "s@DESTINATION-PATH@$2/obsidian.sh@g" "$2/obsidian.desktop"
sed -i -e "s@ICON-PATH@$2/obsidian.png@g" "$2/obsidian.desktop"
chmod -R 777 "$2/"
echo "Obsidian installed successfully."

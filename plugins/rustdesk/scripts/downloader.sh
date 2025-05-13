#!/bin/bash
set -e

echo "Installing $1 -> $2"

# install wget
apt update
apt install -y wget

echo "Installing rustdesk..."
wget -O "/tmp/rustdesk.AppImage" $1

chmod +x /tmp/rustdesk.AppImage
echo "Extracting rustdesk..."
/tmp/rustdesk.AppImage --appimage-extract > /dev/null
cp -r -v ./squashfs-root "$2/"
cd -
cp -v ./rustdesk.sh $2/
chmod +x "$2/rustdesk.sh"

# app icon setup
cp "./assets/rustdesk.png" "$2/rustdesk.png"
cp "./assets/rustdesk.desktop" "$2/rustdesk.desktop"

# replace our icon/exec placeholder strings with proper values
cd $2
pwd
ls -la
sed -i -e "s@DESTINATION-PATH@$2/rustdesk.sh@g" "$2/rustdesk.desktop"
sed -i -e "s@ICON-PATH@$2/rustdesk.png@g" "$2/rustdesk.desktop"
echo "Adding desktop file"
echo "Desktop file created."
chmod -R 777 "$2/"
cat $2/*.desktop




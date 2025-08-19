#!/bin/bash
set -e
# install wget
apt update
echo "installing wget"
apt install -y wget
echo "Installing firefox..."
echo $2
cd /tmp
wget -q -O /tmp/firefox.appimage "$1"
chmod +x /tmp/firefox.appimage

echo "Extracting firefox..."
/tmp/firefox.appimage --appimage-extract > /dev/null
cp -r -v ./squashfs-root "$2/"
cd -
cp -v ./firefox.sh $2/
sed -i "s@ROOT_APP@$2@g" "$2/firefox.sh"
chmod +x "$2/firefox.sh"

# app icon setup
cp "./assets/firefox.png" "$2/firefox.png"
cp "./assets/firefox.desktop" "$2/firefox.desktop"
# replace our icon/exec placeholder strings with proper values
cd $2
pwd
ls -la
sed -i -e "s@DESTINATION-PATH@$2/firefox.sh@g" "$2/firefox.desktop"
sed -i -e "s@ICON-PATH@$2/firefox.png@g" "$2/firefox.desktop"
echo "Adding desktop file"
echo "Desktop file created."
chmod -R 777 "$2/"
cat $2/*.desktop

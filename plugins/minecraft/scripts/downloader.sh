#!/bin/bash
set -e

echo "Installing $1 -> $2"

# install wget
apt update
apt install -y wget

cd /tmp/
wget "$1"
tar -xvzf Minecraft.tar.gz
ls -la
mv -v minecraft-launcher/* "$2/"

# app icon setup
cp "./assets/minecraft.png" "$2/minecraft.png"
cp "./assets/minecraft.desktop" "$2/minecraft.desktop"

# replace our icon/exec placeholder strings with proper values
cd $2
pwd
ls -la
sed -i -e "s@DESTINATION-PATH@$2/minecraft-launcher@g" "$2/minecraft.desktop"
sed -i -e "s@ICON-PATH@$2/minecraft.png@g" "$2/minecraft.desktop"
echo "Adding desktop file"
echo "Desktop file created."
chmod -R 777 "$2/"
cat $2/*.desktop




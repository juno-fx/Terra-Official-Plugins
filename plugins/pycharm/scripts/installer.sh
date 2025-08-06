#!/bin/bash
set -e
# install wget
apt update
echo "installing wget"
apt install -y wget

executable="$(echo "$VERSION" | cut -d'v' -f1)"
LAUNCH="$DESTINATION/pycharm-community-$VERSION/$executable"
ICON="$DESTINATION/pycharm.png"

echo "Installing $VERSION"
echo "Destination $DESTINATION"
echo "Executable: $executable"

cd /tmp

wget -q -O /tmp/pycharm-community-$VERSION "https://download.jetbrains.com/python/pycharm-community-$VERSION.tar.gz"
chmod +x /tmp/pycharm-community-$VERSION.tar.gz

echo "Extracting pycharm..."
tar xzvf /tmp/pycharm-community-$VERSION.tar.gz -C $DESTINATION/

chmod -R 777 $DESTINATION/pycharm-community-$VERSION
chmod -R 777 $DESTINATION

# app icon setup
cp -v ./assets/pycharm.png $DESTINATION/
rm -rfv "$DESTINATION/pycharm.desktop"

echo "[Desktop Entry]
Version=$DESTINATION
Name=Pycharm Community $DESTINATION
Comment=Pycharm Community IDE
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> $DESTINATION/pycharm.desktop

cat $DESTINATION/*.desktop
#!/bin/bash
set -e
# install wget
apt update
echo "installing wget"
apt install -y wget

LAUNCH="$DESTINATION/$VERSION/$executable"
ICON="$DESTINATION/pycharm.png"

echo "Installing $VERSION"
echo "Destination $DESTINATION"

cd /tmp
wget -O pycharm-$VERSION -P /tmp "https://download-cdn.jetbrains.com/python/pycharm-$VERSION.tar.gz"
chmod +x /tmp/pycharm-$VERSION.tar.gz

echo "Extracting pycharm..."
tar xzvf /tmp/pycharm-$VERSION.tar.gz -C $DESTINATION/

chmod -R 777 $DESTINATION/$VERSION
chmod -R 777 $DESTINATION

# app icon setup
cp -v ./assets/pycharm.png $DESTINATION/
rm -rfv "$DESTINATION/pycharm.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=Pycharm $VERSION
Comment=Pycharm IDE
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> $DESTINATION/pycharm.desktop

cat $DESTINATION/*.desktop
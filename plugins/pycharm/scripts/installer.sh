#!/bin/bash
set -e
# install curl
apt update
apt install curl -y

LAUNCH="$DESTINATION/pycharm-$VERSION/bin/pycharm.sh "
ICON="$DESTINATION/pycharm.png"

echo "Installing $VERSION"
echo "Destination $DESTINATION"

curl -o /tmp/pycharm-$VERSION.tar.gz -P /tmp "https://download-cdn.jetbrains.com/python/pycharm-$VERSION.tar.gz"

echo "Extracting pycharm..."
mkdir -p "$DESTINATION"
tar xzvf /tmp/pycharm-$VERSION.tar.gz -C $DESTINATION/
chmod -R 555 $DESTINATION

echo "Adding desktop files"
# app icon setup
cp -v ${PWD}/assets/pycharm.png $DESTINATION/
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
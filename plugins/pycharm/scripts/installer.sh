#!/bin/bash
set -e
# install curl
apt update
apt install curl -y

INSTALL_DIR = "$DESTINATION/pycharm-$VERSION"
LAUNCH="$INSTALL_DIR/bin/pycharm.sh "
ICON="$INSTALL_DIR/pycharm.png"

echo "Installing $VERSION"
echo "Destination $INSTALL_DIR"

curl -o /tmp/pycharm-$VERSION.tar.gz -P /tmp "https://download-cdn.jetbrains.com/python/pycharm-$VERSION.tar.gz"

echo "Extracting pycharm..."
mkdir -p "$INSTALL_DIR"
tar xzvf /tmp/pycharm-$VERSION.tar.gz -C $DESTINATION/
chmod -R 555 $DESTINATION

echo "Adding desktop files"
# app icon setup
cp -v ${PWD}/assets/pycharm.png $INSTALL_DIR/
rm -rfv "$INSTALL_DIR/pycharm.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=Pycharm $VERSION
Comment=Pycharm IDE
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> $INSTALL_DIR/pycharm.desktop

cat $INSTALL_DIR/*.desktop
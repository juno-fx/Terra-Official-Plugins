#!/bin/bash
set -e
# install wget
apt update
echo "installing wget"
apt install -y wget

LAUNCH="$DESTINATION/pycharm-$VERSION/bin/pycharm.sh "
ICON="$DESTINATION/pycharm.png"

# store our current working dir
working_dir="$PWD"
echo $working_dir

echo "Installing $VERSION"
echo "Destination $DESTINATION"

cd /tmp
wget -q -O pycharm-$VERSION.tar.gz -P /tmp "https://download-cdn.jetbrains.com/python/pycharm-$VERSION.tar.gz"
chmod +x /tmp/pycharm-$VERSION.tar.gz

echo "Extracting pycharm..."
mkdir -p "$DESTINATION"
tar xzvf /tmp/pycharm-$VERSION.tar.gz -C $DESTINATION/
chmod -R 777 $DESTINATION

echo "Adding desktop files"
# app icon setup
cd $working_dir
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
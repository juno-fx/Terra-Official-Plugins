#!/bin/bash
set -e
# install wget
apt update
echo "installing wget"
apt install -y wget
echo "Installing pycharm..."
echo $2
cd /tmp

wget -q -O /tmp/pycharm-community-$1.tar.gz "https://download.jetbrains.com/python/pycharm-community-$1.tar.gz"
chmod +x /tmp/pycharm-community-$1.tar.gz

echo "Extracting pycharm..."
tar xzvf /tmp/pycharm-community-$1.tar.gz -C $2/

chmod -R 777 $2/pycharm-community-$1
chmod -R 777 $2

# app icon setup
cp "./assets/pycharm.png" "$2/pycharm.png"
cp "./assets/pycharm.desktop" "$2/pycharm.desktop"
# replace our icon/exec placeholder strings with proper values
cd $2
pwd
ls -la
sed -i -e "s@DESTINATION-PATH@$2/pycharm.sh@g" "$2/pycharm.desktop"
sed -i -e "s@ICON-PATH@$2/pycharm.png@g" "$2/pycharm.desktop"
echo "Adding desktop file"
echo "Desktop file created."
chmod -R 777 "$2/"
cat $2/*.desktop

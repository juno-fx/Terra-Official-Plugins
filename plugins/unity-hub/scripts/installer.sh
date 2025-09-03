set -e

echo "installing needed packages"
apt update
apt install wget -y
apt install gnupg -y
apt install binutils -y
INSTALL_DIR="$DESTINATION/unity-hub"
LAUNCH="$INSTALL_DIR/unityhub"
ICON="$INSTALL_DIR/unity.png"
TEMP_LOCATION='/tmp/unity-hub'

echo "Destination $INSTALL_DIR"

wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null

sh -c 'echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list'

apt update
echo "getting unity download url"
URL=$(apt-get --print-uris download unityhub | awk '{print $1}' | tr -d "'")

echo "Downloading Unity Hub"
echo $URL

mkdir -p "$TEMP_LOCATION"
wget -O "$TEMP_LOCATION/unity-hub.deb" "$URL"

echo "Extracting Unity Hub..."
mkdir -p $INSTALL_DIR
#dpkg-deb -xv "$TEMP_LOCATION/unity-hub.deb" "$TEMP_LOCATION"
ar vx "$TEMP_LOCATION/unity-hub.deb" "$TEMP_LOCATION"
tar xzvf "$TEMP_LOCATION/data.tar.gz"-C "$INSTALL_DIR/"
chmod -R 555 "$INSTALL_DIR"

echo "Adding desktop files"

# app icon setup
cp -v "${PWD}/assets/unity.png" "$INSTALL_DIR/"
rm -rfv "$INSTALL_DIR/unity.desktop"

echo "[Desktop Entry]
Name=unity Hub
Comment=Unity Hub
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$INSTALL_DIR"/unity.desktop


cat "$INSTALL_DIR"/*.desktop


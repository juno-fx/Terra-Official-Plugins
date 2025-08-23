set -e

apt update
apt install curl -y
apt install jq -y

INSTALL_DIR="$DESTINATION/unity-$VERSION"
LAUNCH="$INSTALL_DIR/bin/unity.sh"
ICON="$INSTALL_DIR/unity.png"

echo "Installing $VERSION"
echo "Destination $INSTALL_DIR"

reponse_url="https://services.api.unity.com/unity/editor/release/v1/releases?version=$VERSION&platform=LINUX"
echo $response_url
response=$(curl "$reponse_url")
url=$(echo "$test" | jq -r '.results[0].downloads[0].url')

curl -o "/tmp/unity-$VERSION.tar.gz" -P /tmp "$url"

echo "Extracting Unity..."
mkdir -p "$INSTALL_DIR"
tar xzvf "/tmp/unity-$VERSION.tar.gz" -C "$DESTINATION/"
chmod -R 555 "$DESTINATION"

echo "[Desktop Entry]
Version=$VERSION
Name=unity $VERSION
Comment=Unity Game Engine
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$DESTINATION/$VERSION"/unity.desktop

echo "[Desktop Entry]
Version=$VERSION
Name=unity $VERSION GPU
Comment=Unity Game Engine
Exec=vglrun -d /dev/dri/card0 $LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$DESTINATION/$VERSION"/unity-gpu.desktop

cat "$DESTINATION"/*.desktop


set -e

apt update
apt install curl -y
apt install jq -y

INSTALL_DIR="$DESTINATION/unity-$VERSION"
LAUNCH="$INSTALL_DIR/bin/unity.sh"
ICON="$INSTALL_DIR/unity.png"

echo "Installing $VERSION"
echo "Destination $INSTALL_DIR"

response_url="https://services.api.unity.com/unity/editor/release/v1/releases?version=$VERSION&platform=LINUX"
echo "Service API Request URL: $response_url"
response=$(curl -s "$response_url")

url=$(echo "$response" | jq -r '.results[0].downloads[0].url')
echo "Download URL: $url"
curl -o "/tmp/unity-$VERSION.tar.xz" -P /tmp "$url"

echo "Extracting Unity..."
mkdir -p "$INSTALL_DIR"
tar xJvf "/tmp/unity-$VERSION.tar.xz" -C "$DESTINATION/"
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


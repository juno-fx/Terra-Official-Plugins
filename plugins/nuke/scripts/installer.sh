set -e

apt update
apt install curl -y

EXECUTABLE="$(echo "Nuke$VERSION" | cut -d'v' -f1)"
INSTALL_DIR="$DESTINATION/Nuke$VERSION/"
LAUNCH="$INSTALL_DIR/$EXECUTABLE"
ICON="$DESTINATION/Nuke$VERSION/nuke.png"

echo "Installing $VERSION"
echo "Destination $DESTINATION"
echo "Executable: $EXECUTABLE"


curl -Lo "/tmp/Nuke$VERSION.tgz" -P /tmp "https://thefoundry.s3.amazonaws.com/products/nuke/releases/$VERSION/Nuke$VERSION-linux-x86_64.tgz"

echo "Extracting nuke..."
tar xzvf "/tmp/Nuke$VERSION.tgz" -C /tmp/
"/tmp/Nuke$VERSION-linux-x86_64.run" --prefix="$DESTINATION/" --accept-foundry-eula

rm -rfv "$DESTINATION/Nuke$VERSION.tgz" "$DESTINATION/Nuke$VERSION-linux-x86_64.run"

# app icon setup
cp -v ./assets/nuke.png "$INSTALL_DIR"
rm -rfv "$INSTALL_DIR/nuke.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=Nuke $VERSION
Comment=Nuke compositing software
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$INSTALL_DIR/"nuke.desktop

cat "$INSTALL_DIR/"*.desktop

echo "Nuke Terra Install Complete"

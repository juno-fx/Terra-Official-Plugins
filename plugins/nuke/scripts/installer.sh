set -e

apt update
apt install curl -y

executable="$(echo "Nuke$VERSION" | cut -d'v' -f1)"
LAUNCH="$DESTINATION/Nuke$VERSION/$executable"
ICON="$DESTINATION/Nuke$VERSION/nuke.png"

echo "Installing $VERSION"
echo "Destination $DESTINATION"
echo "Executable: $executable"

curl -Lo "/tmp/Nuke$VERSION.tgz" -P /tmp "https://thefoundry.s3.amazonaws.com/products/nuke/releases/$VERSION/Nuke$VERSION-linux-x86_64.tgz"
echo "Extracting nuke..."
tar xzvf "/tmp/Nuke$VERSION.tgz" -C /tmp/
"/tmp/Nuke$VERSION-linux-x86_64.run" --prefix="$DESTINATION/" --accept-foundry-eula

rm -rfv "$DESTINATION/Nuke$VERSION.tgz" "$DESTINATION/Nuke$VERSION-linux-x86_64.run"

# app icon setup
cp -v ./assets/nuke.png "$DESTINATION/Nuke$VERSION/"
rm -rfv "$DESTINATION/nuke.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=Nuke $VERSION
Comment=Nuke compositing software
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$DESTINATION/Nuke$VERSION"/nuke.desktop

cat "$DESTINATION/Nuke$VERSION/*.desktop"


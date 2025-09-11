set -e

apt update
apt install curl -y

executable="$(echo "$VERSION" | cut -d'v' -f1)"
LAUNCH="$DESTINATION/$VERSION/$executable"
ICON="$DESTINATION/$VERSION/nuke.png"

echo "Installing $VERSION"
echo "Destination $DESTINATION"
echo "Executable: $executable"

curl -LJO -o nuke.tgz "https://thefoundry.s3.amazonaws.com/products/nuke/releases/$VERSION/Nuke$VERSION-linux-x86_64.tgz"
mv -v "download_product" "/tmp/$VERSION.tgz"

tar -xvf "/tmp/$VERSION.tgz" -C /tmp/
"/tmp/$VERSION-linux-x86_64.run" --prefix="$DESTINATION/" --accept-foundry-eula

rm -rfv "$DESTINATION/$VERSION.tgz" "$DESTINATION/$VERSION-linux-x86_64.run"

# app icon setup
cp -v ./assets/nuke.png "$DESTINATION/$VERSION/"
rm -rfv "$DESTINATION/nuke.desktop"

echo "[Desktop Entry]
Version=$VERSION
Name=Nuke $VERSION
Comment=Nuke compositing software
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$DESTINATION/$VERSION"/nuke.desktop

echo "[Desktop Entry]
Version=$VERSION
Name=Nuke $VERSION GPU
Comment=Nuke compositing software GPU enabled
Exec=vglrun -d /dev/dri/card0 $LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$DESTINATION/$VERSION"/nuke-gpu.desktop

cat "$DESTINATION"/*.desktop


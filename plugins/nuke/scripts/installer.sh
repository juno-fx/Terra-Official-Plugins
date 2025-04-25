set -e

apt update
apt install curl -y

LAUNCH="$DESTINATION/$VERSION/$executable"
ICON="$DESTINATION/nuke.png"
executable="$(echo "$VERSION" | cut -d'v' -f1)"

echo "Installing $VERSION"
echo "Destination $DESTINATION"
echo "Executable: $executable"

curl -LJO -o nuke.tgz "https://www.foundry.com/products/download_product?file=$VERSION-linux-x86_64.tgz"
mv -v "download_product" "/tmp/$VERSION.tgz"

tar -xvf "/tmp/$VERSION.tgz" -C /tmp/
"/tmp/$VERSION-linux-x86_64.run" --prefix="$DESTINATION/" --accept-foundry-eula

rm -rfv "$DESTINATION/$VERSION.tgz" "$DESTINATION/$VERSION-linux-x86_64.run"

# app icon setup
cp -v ./assets/nuke.png $DESTINATION/

echo "[Desktop Entry]
Version=$VERSION
Name=Nuke $VERSION
Comment=Nuke compositing software
Exec=junogl $LAUNCH
Icon=$ICON
Terminal=false
Type=Application
Categories=X-Polaris" >> $DESTINATION/nuke.desktop

cat $DESTINATION/*.desktop


wget -q -O /tmp/flameshot.appimage "$1"
chmod +x /tmp/flameshot.appimage
/tmp/flameshot.appimage --appimage-extract > /dev/null
mv ./squashfs-root "$2/"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cp -v "$SCRIPT_DIR/flameshot.sh" "$2/"
chmod +x "$2/flameshot.sh"

# app icon setup
cp "../assets/flameshot.png" "$2/flameshot.png"

# desktop file setup
echo "
[Desktop Entry]
Name=Flameshot
Exec=/bin/bash -x $2/flameshot.sh
Terminal=true
Type=Application
Categories=Apps
Icon=$2/flameshot.png" > "$2/flameshot.desktop"


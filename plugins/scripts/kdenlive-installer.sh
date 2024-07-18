wget -q -O /tmp/kdenlive.appimage "$1"
chmod +x /tmp/kdenlive.appimage
/tmp/kdenlive.appimage --appimage-extract > /dev/null
mv ./squashfs-root "$2/"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cp -v "$SCRIPT_DIR/kdenlive.sh" "$2/"
chmod +x "$2/kdenlive.sh"

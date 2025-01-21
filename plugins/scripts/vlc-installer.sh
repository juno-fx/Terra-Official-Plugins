echo "Install vlc"
mkdir -p "$2"
echo "Downloading vlc..."
wget -q -O /tmp/vlc.appimage "$1"
chmod +x /tmp/vlc.appimage
cd /tmp
./vlc.appimage --appimage-extract > /dev/null

mv /tmp/squashfs-root "$2"



SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cp -v "$SCRIPT_DIR/vlc.sh" "$2/"
sed -i "s@ROOT_APP@$2@g" "$2/vlc.sh"
chmod +x "$2/vlc.sh"
chmod -R 777 "$2/"

# app icon setup
cd $SCRIPT_DIR
cp "../assets/vlc.png" "$2/vlc.png"
echo "Adding desktop file"
chmod +X create_desktop_file.py
python3 create_desktop_file.py --app_name="vlc" --version="3.6" --latest_path="$2"/vlc.sh --categories="audio, vlc" --destination="$2" --icon="$2"/vlc.png
echo "Desktop file created."
chmod -R 777 "$2"

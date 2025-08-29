
set -e

echo "Installing $VERSION - $DESTINATION"

echo "Setting up prequesites"
apt update
apt install bc wget unzip python3 python3-venv python3-pip -y
apt install p7zip -y
python3 -m venv venv
source venv/bin/activate
venv/bin/pip --version

venv/bin/pip  install requests
venv/bin/pip  install click


# store our current working dir
WORKING_DIR="$PWD"
echo $WORKING_DIR

# We need to pass export SIDEFX_CLIENT_ID=''; export SIDEFX_CLIENT_SECRET=''; export DEV_APPS_DEBUG=true to the scipt itself
export SIDEFX_CLIENT_ID=$CLIENT_ID
export SIDEFX_CLIENT_SECRET=$CLIENT_SECRET

# Hardcoding until we can sort out a way to gather the license date from new launcher installer
export LICENSE_DATE="SideFX-2021-10-13"
# split our version/build values
echo "version"
echo $VERSION
export HOUDINI_VERSION="${VERSION%.*}"
export HOUDINI_BUILD="${VERSION##*.}"
INSTALL_DIR="$DESTINATION/$VERSION"

TEMP_FOLDER="/tmp/apps_temp"
mkdir -p $TEMP_FOLDER
mkdir -p "$TEMP_FOLDER"/"$VERSION"
mkdir -p "$TEMP_FOLDER"/"$VERSION"/installs
TEMP_VERSION_FOLDER="$TEMP_FOLDER"/"$VERSION"
echo $TEMP_VERSION_FOLDER
echo "Downloading Houdini $VERSION"

venv/bin/python "$WORKING_DIR/sidefx_downloader.py" --version $HOUDINI_VERSION --build $HOUDINI_BUILD --key "$SIDEFX_CLIENT_ID" --secret "$SIDEFX_CLIENT_SECRET" --output "$TEMP_VERSION_FOLDER"

echo "Extracting houdini-launcher.iso"

chmod 555 "$TEMP_VERSION_FOLDER"/houdini-installer.iso
7z x "$TEMP_VERSION_FOLDER"/houdini-installer.iso -o"$TEMP_VERSION_FOLDER"

echo "houdini-installer.iso extracted to "$TEMP_VERSION_FOLDER""
echo "Installing Houdini Launcher... "$INSTALL_DIR"/launcher ..."

mkdir -p "$DESTINATION"
chmod -R 555 "$DESTINATION"
mkdir -p "$INSTALL_DIR"
chmod -R 555 "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/launcher"
chmod -R 555 "$INSTALL_DIR/launcher"
mkdir -p "$INSTALL_DIR/shfs"
chmod -R 555 "$INSTALL_DIR/shfs"
echo "Houdini Install Dir: "$INSTALL_DIR"/launcher"

cd "$TEMP_VERSION_FOLDER"/houdini-installer
echo $PWD
ls
./houdini-launcher.sh "$INSTALL_DIR"/launcher

echo "License Date:" $LICENSE_DATE
echo "Running Houdini Installer for $VERSION"

cd "$INSTALL_DIR"
./launcher/bin/houdini_installer install --product Houdini --version "$Version" --install-shfs --shfs-directory "$INSTALL_DIR/shfs" --install-package --installdir "$INSTALL_DIR" --offline-installer "$TEMP_VERSION_FOLDER/houdini-installer.iso" --accept-EULA="$LICENSE_DATE"

echo "cleaning up temp files"
rm -rf $TEMP_VERSION_FOLDER/houdini-launcher.iso

echo "Adding desktop files"
cd "$WORKING_DIR"
# app icon setup
cp -v ./assets/houdini.png INSTALL_DIR/

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini FX $VERSION
Comment=SideFX Houdini software
Exec=vglrun -d /dev/dri/card0 $INSTALL_DIR/bin/houdinifx %F
Icon="$INSTALL_DIR/houdini.png"
Terminal=true
Type=Application
Categories=X-Polaris" > $INSTALL_DIR/houdinifx_$VERSION.desktop

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini Core $VERSION
Comment=SideFX Houdini software
Exec=vglrun -d /dev/dri/card0 $INSTALL_DIR/bin/houdinicore %F
Icon="$INSTALL_DIR/houdini.png"
Terminal=true
Type=Application
Categories=X-Polaris" > $INSTALL_DIR/houdinicore_$VERSION.desktop

# set permission for desktop files and copy over to applications dir
chmod 644 $INSTALL_DIR/houdinicore_$VERSION.desktop
chmod 644 $INSTALL_DIR/houdinifx_$VERSION.desktop


cat $INSTALL_DIR/*.desktop

echo "Desktop file created."
echo "Install Complete"

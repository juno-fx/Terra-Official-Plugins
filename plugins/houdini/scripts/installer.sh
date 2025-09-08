
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

# We need to pass export SIDEFX_CLIENT_ID=''; export SIDEFX_CLIENT_SECRET=''
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
mkdir -p "$TEMP_FOLDER"/"$VERSION"/installs
TEMP_VERSION_FOLDER="$TEMP_FOLDER"/"$VERSION"
echo $TEMP_VERSION_FOLDER
echo "Downloading Houdini $VERSION"

venv/bin/python "$WORKING_DIR/sidefx_downloader.py" \
--version $HOUDINI_VERSION \
--build $HOUDINI_BUILD \
--key "$SIDEFX_CLIENT_ID" \
--secret "$SIDEFX_CLIENT_SECRET" \
--output "$TEMP_VERSION_FOLDER"

if [ ! -f "$TEMP_VERSION_FOLDER"/houdini-installer.iso ]; then
    echo "Unable to find download for $VERSION. exiting..."
    exit 1
fi

echo "Extracting houdini-launcher.iso"

chmod 555 "$TEMP_VERSION_FOLDER"/houdini-installer.iso
7z x "$TEMP_VERSION_FOLDER"/houdini-installer.iso -o"$TEMP_VERSION_FOLDER/installs"

echo "houdini-installer.iso extracted to "$TEMP_VERSION_FOLDER""
echo "Installing Houdini Launcher... "$INSTALL_DIR"/launcher ..."

mkdir -p "$INSTALL_DIR/launcher"
mkdir -p "$INSTALL_DIR/shfs"
chmod -R 555 "$DESTINATION" "$INSTALL_DIR" "$INSTALL_DIR/launcher" "$INSTALL_DIR/shfs"



cd "$TEMP_VERSION_FOLDER/installs"
ls

echo "Installing launcher to $INSTALL_DIR/launcher"
chmod +x ./install_houdini_launcher.sh
./install_houdini_launcher.sh "$INSTALL_DIR"/launcher

echo "License Date:" $LICENSE_DATE
cd "$INSTALL_DIR"
ls

echo "Installing Houdini $VERSION to $INSTALL_DIR/houdini"
./launcher/bin/houdini_installer install \
--product Houdini \
--version "$VERSION" \
--shfs-directory "$INSTALL_DIR/shfs" \
--installdir "$INSTALL_DIR/houdini" \
--offline-installer "$TEMP_VERSION_FOLDER/houdini-installer.iso" \
--accept-EULA="$LICENSE_DATE"

echo "Installing SideFX Labs Production Build $HOUDINI_VERSION to $INSTALL_DIR/sidefx_packages"
./launcher/bin/houdini_installer install-package \
--package-name "SideFX Labs $HOUDINI_VERSION Production Build" \
--installdir "$INSTALL_DIR/sidefx_packages"

echo "cleaning up temp files"
rm -rf "$TEMP_VERSION_FOLDER"

echo "Adding desktop files"
cd "$WORKING_DIR"
# app icon setup
cp -v ./assets/houdini.png "$INSTALL_DIR"/

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini FX $VERSION
Comment=SideFX Houdini software
Exec=$INSTALL_DIR/houdini/bin/houdinifx %F
Icon="$INSTALL_DIR/houdini.png"
Terminal=true
Type=Application
Categories=X-Polaris" > $INSTALL_DIR/houdini_fx_$VERSION.desktop

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini Core $VERSION
Comment=SideFX Houdini software
Exec=$INSTALL_DIR/houdini/bin/houdinicore %F
Icon="$INSTALL_DIR/houdini.png"
Terminal=true
Type=Application
Categories=X-Polaris" > $INSTALL_DIR/houdini_core_$VERSION.desktop

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini Launcher $VERSION
Comment=SideFX Houdini software Launcher
Exec=$INSTALL_DIR/launcher/bin/houdini_launcher
Icon="$INSTALL_DIR/houdini.png"
Terminal=true
Type=Application
Categories=X-Polaris" > $INSTALL_DIR/houdini_launcher_$VERSION.desktop

# set permission for desktop files and copy over to applications dir
chmod 644 $INSTALL_DIR/houdini_core_$VERSION.desktop
chmod 644 $INSTALL_DIR/houdini_fx_$VERSION.desktop
chmod 644 $INSTALL_DIR/houdini_launcher_$VERSION.desktop

cat $INSTALL_DIR/*.desktop

echo "Desktop file created."
echo "Install Complete"

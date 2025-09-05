#!/bin/bash
set -e

# Update packages and install wget
apt update
apt install -y wget unzip

# Set local variables
LAUNCH="$DESTINATION/EmberGen-$VERSION/embergen2"
ICON="$DESTINATION/EmberGen-$VERSION/embergen.png"
DESKTOP_FILE="$DESTINATION/EmberGen-$VERSION/embergen.desktop"
DESKTOP_FILE_GPU="$DESTINATION/EmberGen-$VERSION/embergen-gpu.desktop"

# Download and Install the application
echo "Installing Embergen Version $VERSION into $DESTINATION"
echo "Downloading Embergen..."
wget -O "/tmp/embergen-$VERSION-linux.zip" "https://jangafx-software-files.s3.amazonaws.com/embergen/installers/linux/embergen-$VERSION-linux.zip"

echo "Extracting Embergen..."
unzip -o "/tmp/embergen-$VERSION-linux.zip" -d "$DESTINATION"

chmod -R 555 "$DESTINATION"

# App icon setup
echo "Adding desktop files"
cp -v "${PWD}/assets/embergen.png" "$DESTINATION/EmberGen-$VERSION"
rm -rfv "$DESKTOP_FILE"

echo "[Desktop Entry]
Version=$VERSION
Name=Embergen $VERSION
Comment=Real-time volumetric effects
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris
MimeType=application/x-embergen
StartupWMClass=Embergen" >> "$DESKTOP_FILE"

echo "[Desktop Entry]
Version=$VERSION
Name=Embergen $VERSION GPU
Comment=Real-time volumetric effects
Exec=vglrun -d /dev/dri/card0 $LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris
MimeType=application/x-embergen
StartupWMClass=Embergen" >> "$DESKTOP_FILE_GPU"

echo "Desktop file created at $DESKTOP_FILE"
echo "Desktop file created at $DESKTOP_FILE_GPU"
cat "$DESTINATION/EmberGen-$VERSION/"*.desktop
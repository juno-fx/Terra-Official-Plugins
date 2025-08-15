#!/bin/bash
set -e

# Update packages and install wget
apt update
apt install -y wget xz-utils

# Set local variables
INSTALL_DIR="$DESTINATION/blender-$VERSION-linux-x64"
LAUNCH="$INSTALL_DIR/blender %f"
ICON="$INSTALL_DIR/blender.png"
DESKTOP_FILE="$INSTALL_DIR/blender-$VERSION.desktop"
DESKTOP_FILE_GPU="$INSTALL_DIR/blender-$VERSION-gpu.desktop"
RELEASE=$(echo $VERSION | cut -d'.' -f1-2) # split 4.5.1 to 4.5

# Download and Install the application
echo "Installing Blender Version $VERSION into $INSTALL_DIR"
echo "Downloading Blender..."
wget -O "/tmp/blender-$VERSION-linux-x64.tar.xz" "https://download.blender.org/release/Blender$RELEASE/blender-$VERSION-linux-x64.tar.xz"

echo "Extracting Blender..."
mkdir -p ${INSTALL_DIR}
tar -xJvf "/tmp/blender-$VERSION-linux-x64.tar.xz" -C "$DESTINATION/"
chmod -R 555 "$INSTALL_DIR"

# App icon setup
echo "Adding desktop files"
cp -v "${PWD}/assets/blender.png" "$DESTINATION/"
rm -rfv "$DESKTOP_FILE"

echo "[Desktop Entry]
Version=$VERSION
Name=Blender $VERSION
Comment=3D modeling, animation, rendering and post-production
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris
MimeType=application/x-blender
StartupWMClass=Blender" >> "$DESKTOP_FILE"

echo "[Desktop Entry]
Version=$VERSION
Name=Blender $VERSION GPU
Comment=3D modeling, animation, rendering and post-production
Exec=vglrun -d /dev/dri/card0 $LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris
MimeType=application/x-blender
StartupWMClass=Blender" >> "$DESKTOP_FILE_GPU"

echo "Desktop file created at $DESKTOP_FILE"
echo "Desktop file created at $DESKTOP_FILE_GPU"
cat "$INSTALL_DIR"/*.desktop
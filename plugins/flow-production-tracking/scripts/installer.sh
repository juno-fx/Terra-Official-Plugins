#!/bin/bash
set -e

# Update packages and install wget
apt update
apt install -y wget xz-utils rpm2cpio cpio

# Set local variables
INSTALL_DIR="$DESTINATION/flow-production-tracking"
LAUNCH="$INSTALL_DIR/Shotgun"
ICON="$INSTALL_DIR/flow.png"
DESKTOP_FILE="$INSTALL_DIR/flow-production-tracking.desktop"
RPM_FILE="flow.rpm"

# Download and Install the application
echo "Installing Autodesk Flow Production Tracking into $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Downloading Autodesk Flow Production Tracking..."
wget -O "$RPM_FILE" "$URL"

# Extract the RPM package
echo "Extracting Flow Production Tracking..."
rpm2cpio "$RPM_FILE" | cpio -idmv
echo "Extraction complete."

# Move the extracted files to the installation directory
echo "Moving files to $INSTALL_DIR"
mv opt/Shotgun/* .
echo "Files moved."

echo "Cleaning up files"
rm -rf opt
rm -rf "$RPM_FILE"
echo "Cleanup complete."

# App icon setup
echo "Adding desktop files"
cp -v "/terra/scripts/assets/flow.png" "$INSTALL_DIR/"
rm -rfv "$DESKTOP_FILE"

echo "[Desktop Entry]
Name=Autodesk Flow Production Tracking
Comment=Autodesk Flow Production Tracking
Exec=$LAUNCH
Icon=$ICON
Terminal=true
Type=Application
Categories=X-Polaris" >> "$DESKTOP_FILE"

echo "Desktop file created at $DESKTOP_FILE"
cat "$DESKTOP_FILE"
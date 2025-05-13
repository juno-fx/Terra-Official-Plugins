#!/bin/bash
set -e

echo "Installing $1"

# install wget
apt update
apt install -y wget

echo "Downloading Deadline installer"
installers=/apps/tmp/deadline10_installers
mkdir -p $installers

if [ "$DEV_APPS_DEBUG" = true ]
then
  echo "Dev Apps Debug is enabled - deadline copied with docker"
else
  # download the installer
  wget -q -O /apps/tmp/Deadline-10.3.2.1-linux-installers.tar "$1"
fi

echo "Downloaded Deadline installer."

# permissions
chmod +x /apps/tmp/Deadline-10.3.2.1-linux-installers.tar

# extract the installer
tar -xvf /apps/tmp/Deadline-10.3.2.1-linux-installers.tar -C $installers
echo "Deadline installer files extracted to $installers"



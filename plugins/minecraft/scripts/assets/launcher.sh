#!/bin/bash
set -e

echo "Launching Minecraft"

rm -rfv ~/.minecraft/webcache2

cd $1
./minecraft-launcher

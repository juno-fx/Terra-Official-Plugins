#!/bin/bash
set -e

echo "Launching Minecraft"

rm -rf ~/.minecraft/webcache2

cd $1
./minecraft-launcher

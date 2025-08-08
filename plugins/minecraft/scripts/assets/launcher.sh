#!/bin/bash
set -e

echo "Launching Minecraft"

rm -rfv ~/.minecraft/launcher/*

cd $1
./minecraft-launcher

#!/bin/bash
set -e

# install wget
apt update
echo "installing wget"
apt install -y wget
echo "Downloading miniconda..."
echo $DESTINATION
cd /tmp

# install miniconda
wget "$URL" -O miniconda.sh
chmod -v +x miniconda.sh
./miniconda.sh -u -b -p "$DESTINATION"
eval "$($DESTINATION/bin/conda shell.bash hook)"
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
conda config --set channel_priority strict

# create the environment and install the packages.
conda create -p $DESTINATION/envs/$ENVIRONMENT_NAME python=$PYTHON_VERSION -y
conda activate $DESTINATION/envs/$ENVIRONMENT_NAME
pip install $PACKAGES
conda deactivate

# set permissions to be shared.
chmod -R 7777 $DESTINATION



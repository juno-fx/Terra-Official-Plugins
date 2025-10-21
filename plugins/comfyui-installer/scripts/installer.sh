set -e

# build system
apt update
apt install -y git

INSTALL_DIR="$DESTINATION/comfyui"
# cd to the destination directory
mkdir -p "$DESTINATION"
cd "$DESTINATION"

# clone the repository if it doesn't exist. If it does exist, cd into it and update it
if [ -d "comfyui" ]; then
  echo "ComfyUI directory already exists. Updating..."
  cd comfyui
  git pull origin master
else
  echo "Cloning ComfyUI repository..."
  git clone https://github.com/comfyanonymous/ComfyUI.git --depth 1 comfyui
  cd comfyui
fi

# prepare the python environment
pip install uv

# install python to the system
# if $INSTALL_DIR/py_install/cpython-3.12.11-linux-x86_64-gnu does not exist, then install it
if [ ! -d "$INSTALL_DIR/py_install/cpython-3.12.11-linux-x86_64-gnu" ]; then
  echo "Installing Python 3.12.11..."
  uv python install -f -r -i py_install 3.12.11
else
  echo "Python 3.12.11 already installed."
fi

# create the virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  echo "Using Python from: $INSTALL_DIR/py_install/cpython-3.12.11-linux-x86_64-gnu/bin/python"
  uv venv .venv -p "$INSTALL_DIR/py_install/cpython-3.12.11-linux-x86_64-gnu/bin/python"
else
  echo "Virtual environment already exists."
fi
source .venv/bin/activate
uv pip install --no-cache -r requirements.txt

# install comfyui manger
cd custom_nodes

git config pull.rebase false

# check if the ComfyUI-Manager directory exists, if it does, skip cloning
if [ -d "comfyui-manager" ]; then
  echo "ComfyUI-Manager directory already exists..."
else
  echo "Cloning ComfyUI-Manager repository..."
  git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager
fi
cd comfyui-manager
git pull origin main
uv pip install --no-cache -r requirements.txt
cd ../

# allow the outputs, models, custom_nodes, and input directories to have write permissions
mkdir -p "$INSTALL_DIR/user"
mkdir -p "$INSTALL_DIR/temp"
chmod -R 755 "$INSTALL_DIR/user"
chmod -R 755 "$INSTALL_DIR/temp"
chmod -R 755 "$INSTALL_DIR/output"
chmod -R 755 "$INSTALL_DIR/models"
chmod -R 755 "$INSTALL_DIR/custom_nodes"
chmod -R 755 "$INSTALL_DIR/input"

# step up a directory and create a bash script that will cd to the absolute path of the
# destination directory plus the comfyui directory and run .venv/bin/python main.py --listen 0.0.0.0
cd ..
rm -rfv run_comfyui.sh
echo "#!/bin/bash" > run_comfyui.sh
echo "cd \"$INSTALL_DIR\"" >> run_comfyui.sh
echo ".venv/bin/python main.py --listen 0.0.0.0 --enable-cors-header" >> run_comfyui.sh

# make the script executable
chmod +x run_comfyui.sh

echo "ComfyUI installation and setup completed."


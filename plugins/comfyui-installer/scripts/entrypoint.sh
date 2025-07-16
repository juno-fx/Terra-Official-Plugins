#!/bin/bash

set -e
echo "Starting entrypoint script..."

# check that the DESTINATION environment variable is set
if [ -z "$DESTINATION" ]; then
  echo "DESTINATION environment variable is not set. Exiting."
  exit 1
fi

# check if the INSTALL environment variable is set then update the system
if [ -n "$INSTALL" ]; then
  # build system
  apt update
  apt install -y git

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
  uv python install -f -r -i py_install 3.12.11

  # create the virtual environment if it doesn't exist
  if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    echo "Using Python from: $DESTINATION/comfyui/py_install/cpython-3.12.11-linux-x86_64-gnu/bin/python"
    uv venv .venv -p "$DESTINATION/comfyui/py_install/cpython-3.12.11-linux-x86_64-gnu/bin/python"
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

  # install comfyui distributed

  # check if the ComfyUI-Distributed directory exists, if it does, skip cloning
  if [ -d "ComfyUI-Distributed" ]; then
    echo "ComfyUI-Distributed directory already exists..."
  else
    echo "Cloning ComfyUI-Distributed repository..."
    git clone https://github.com/robertvoy/ComfyUI-Distributed.git
  fi
  cd ../

  # allow the outputs, models, custom_nodes, and input directories to have write permissions
  mkdir -p "$DESTINATION/comfyui/user"
  mkdir -p "$DESTINATION/comfyui/temp"
  chmod -R 777 "$DESTINATION/comfyui/user"
  chmod -R 777 "$DESTINATION/comfyui/temp"
  chmod -R 777 "$DESTINATION/comfyui/output"
  chmod -R 777 "$DESTINATION/comfyui/models"
  chmod -R 777 "$DESTINATION/comfyui/custom_nodes"
  chmod -R 777 "$DESTINATION/comfyui/input"

  # step up a directory and create a bash script that will cd to the absolute path of the
  # destination directory plus the comfyui directory and run .venv/bin/python main.py --listen 0.0.0.0
  cd ..
  echo "#!/bin/bash" > run_comfyui.sh
  echo "cd \"$DESTINATION/comfyui\"" >> run_comfyui.sh
  echo ".venv/bin/python main.py --listen 0.0.0.0 --enable-cors-header" >> run_comfyui.sh

  # make the script executable
  chmod +x run_comfyui.sh

  echo "ComfyUI installation and setup completed."
fi

# check if the CLEANUP environment variable is set
if [ -n "$CLEANUP" ]; then
  # remove the Destination directory
  echo "Cleaning up the destination directory..."
  rm -rf "$DESTINATION"
  echo "Cleanup completed."
fi

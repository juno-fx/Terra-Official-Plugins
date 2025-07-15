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
  pwd
  ls -la

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

  # create the virtual environment if it doesn't exist
  ls -la
  if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    uv venv .venv
  else
    echo "Virtual environment already exists."
  fi
  source .venv/bin/activate
  uv pip install --no-cache -r requirements.txt
  ls -la

  # step up a directory and create a bash script that will cd to the absolute path of the
  # destination directory plus the comfyui directory and run .venv/bin/python main.py --listen 0.0.0.0
  cd ..
  echo "#!/bin/bash" > run_comfyui.sh
  echo "cd \"$DESTINATION/comfyui\"" >> run_comfyui.sh
  echo ".venv/bin/python main.py --listen 0.0.0.0" >> run_comfyui.sh

  # allow the outputs, models, custom_nodes, and input directories to have write permissions
  chmod -R 777 "$DESTINATION/comfyui/outputs"
  chmod -R 777 "$DESTINATION/comfyui/models"
  chmod -R 777 "$DESTINATION/comfyui/custom_nodes"
  chmod -R 777 "$DESTINATION/comfyui/input"

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

# NukeSamurai Installer Script
# requires python3.10
# requires git

apt update -y &&  apt upgrade -y && apt update -y
apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

curl https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv install 3.10.10
pyenv global 3.10
echo "Python 3.10 installed ?"
python3 --version

echo "Installing NukeSamurai to /apps/nuke_samurai"
export BUILDER=/tmp/nuke_samurai
mkdir -p $BUILDER

# git clone the NukeSamurai repo
cd $BUILDER
git clone https://github.com/Theo-SAMINADIN-td/NukeSamurai.git
cd $BUILDER/NukeSamurai
pyenv global 3.10

echo "Installing NukeSamurai PIP deps"
python3 -m venv $BUILDER/NukeSamurai/venv
source venv/bin/activate
echo "Check pip / venv?"
pip --version

#
## pull pip deps
pip install -i https://pypi.org/simple torch==2.3.1+cu118 torchvision==0.18.1 --extra-index-url https://download.pytorch.org/whl/cu118
cd $BUILDER/NukeSamurai/sam2_repo
pip install -i https://pypi.org/simple -e .
pip install -i https://pypi.org/simple -e ".[notebooks]"
pip install -i https://pypi.org/simple matplotlib==3.7 tikzplotlib jpeg4py opencv-python lmdb pandas scipy loguru ninja

# download checkpoints
cd checkpoints
./download_ckpts.sh > /dev/null
echo "Checkpoints downloaded"

# setup nukes init.py to load the venv for us
echo "Setting up Nuke init.py python path"
echo 'nuke.pluginAddPath("/apps/nukesamurai/", addToSysPath=True)' > $BUILDER/NukeSamurai/init.py
echo 'nuke.pluginAddPath("/apps/nukesamurai/NukeSamurai/venv/lib/python3.10/site-packages", addToSysPath=True)' > $BUILDER/NukeSamurai/init.py

mv $BUILDER/NukeSamurai $1

chmod -R 777 $1

echo "NukeSamurai installed to $1"
echo "Adding Juno Spice"
pip install click
# app icon setup
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
cp "../assets/nuke.png" "$2/nuke.png"
echo "Adding desktop file"
chmod +X create_desktop_file.py
python3 create_desktop_file.py --app_name="NukeSamurai" --version=$1 --latest_path="$1"/nukesamurai-start.sh --categories="nuke, samurai" --destination="$1" --icon="$1"/nuke.png --terminal="True"
cp $SCRIPT_DIR/nukesamurai-start.sh $1/nukesamurai-start.sh
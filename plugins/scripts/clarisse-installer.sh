echo "Installing ClarisseIFX to $2"

export PIP_INDEX_URL=https://pypi.org/simple
export UV_LINK_MODE=copy

# we need to rebuild python
apt update -y &&  apt upgrade -y && apt update -y
apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

curl https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv install 3.7
pyenv global 3.7
echo "Python 3.7 installed ?"
python3 --version
# test
pip install --upgrade pip click

wget -q -O /tmp/clarisse.tar.gz "$1"

mkdir -p $2

chmod +x /tmp/clarisse.tar.gz
tar xvf /tmp/clarisse.tar.gz -C $2
mv clarisse "$2/"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cp -v "$SCRIPT_DIR/clarisse.sh" "$2/"
sed -i "s@ROOT_APP@$2@g" "$2/clarisse.sh"
chmod +x "$2/clarisse.sh"
chmod -R 777 "$2/"

# app icon setup
cd $SCRIPT_DIR
cp "../assets/clarisse.png" "$2/clarisse.png"
echo "Adding desktop file"
chmod +X create_desktop_file.py
python3 create_desktop_file.py --app_name="Clarisse" --version="5.0_sp14" --latest_path="$2"/clarisse.sh --categories="clarisse, cpu, rendering" --destination="$2" --icon="$2"/clarisse.png
echo "Desktop file created."
chmod -R 777 "$2/"
cat $2/*.desktop

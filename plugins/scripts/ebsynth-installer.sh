# get deps

apt update -y
apt install software-properties-common -y
add-apt-repository ppa:ubuntu-toolchain-r/test
apt update -y
apt install gcc g++ -y

gcc --version

#export CONDA_ALWAYS_YES="true"
#curl -O https://repo.anaconda.com/archive/Anaconda3-2023.07-2-Linux-x86_64.sh
#bash Anaconda3-2023.07-2-Linux-x86_64.sh -b
#
#source /root/anaconda3/bin/activate
#conda init
#conda install -c "nvidia/label/cuda-12.2.0" cuda-toolkit
#


wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update -y
apt-get -y install cuda-toolkit-12-3

echo "Installing Ebsynth..."

mkdir $2
cd $2
git clone https://github.com/ddesmond/ebsynth.git
# ls ebsynth
cd $2/ebsynth
echo $PWD
export PATH=/usr/local/cuda-12.3/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64\
                         ${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
echo "Building ebsynth... CPU+GPU"
sh build-juno.sh


ls $2/ebsynth
ls $2/ebsynth/bin



#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#cp -v "$SCRIPT_DIR/ebsynth.sh" "$2/"
#sed -i "s@ROOT_APP@$2@g" "$2/ebsynth.sh"
#chmod +x "$2/ebsynth.sh"
#chmod -R 777 "$2/"
## app icon setup
#cd $SCRIPT_DIR
#cp "../assets/ebsynth.png" "$2/ebsynth.png"
#echo "Adding desktop file"
#chmod +X create_desktop_file.py
#python3 create_desktop_file.py --app_name="ebsynth" --version="30.0" --latest_path="$2"/ebsynth.sh --categories="ebsynth" --destination="$2" --icon="$2"/ebsynth.png --terminal="False"
#echo "Desktop file created."

chmod -R 777 "$2/"
#cat $2/*.desktop

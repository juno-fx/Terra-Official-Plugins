set -e
# https://docs.unity3d.com/hub/manual/InstallHub.html

echo "Installing needed packages"
apt update
apt install -y wget
apt install -y gpg

echo "installing Unity Hub"
wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | sudo tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null
sh -c 'echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list'
apt update
apt-get install unityhub
echo "Installing Autodesk Maya..."

#INSTALL DEPS
echo "Install Maya Setup deps"
apt update -y
apt install alien dpkg-dev debhelper build-essential zlib1g-dev -y

temp_install_dir=$2/maya_installer

mkdir -p $temp_install_dir
mkdir -p $2

chmod -R 777 $temp_install_dir/
chmod -R 777 $2

if [ "$DEV_APPS_DEBUG" = true ]
then
  echo "Dev Apps Debug is enabled - maya copied with docker"
else
  # download the installer
  wget -q -O /tmp/mayainstaller.tgz "$1"
fi

# extract the installer
tar -xvzf /tmp/mayainstaller.tgz -C $temp_install_dir
# check maya installer
ls -la /tmp
ls -la $temp_install_dir


# PREP MAYA INSTALLS FOR UBUNTU
cd $temp_install_dir/install/Packages
alien -vc *.rpm

ls -la $temp_install_dir/install/Packages


# INSTALL LICENSING SERVICE
#sudo getent group adsklic &>/dev/null || sudo groupadd adsklic
#sudo id -u adsklic &>/dev/null || sudo useradd -M -r -g adsklic adsklic -d / -s /usr/sbin/nologin
#sudo ln -sf /opt/Autodesk/AdskLicensing/Current/AdskLicensingService/AdskLicensingService /usr/bin/AdskLicensingService
#sudo mkdir /usr/lib/systemd/system
#sudo cp -f /opt/Autodesk/AdskLicensing/Current/AdskLicensingService/adsklicensing.el7.service /usr/lib/systemd/system/adsklicensing.service
#sudo chmod 644 /usr/lib/systemd/system/adsklicensing.service
#sudo systemctl daemon-reload
#sudo systemctl enable adsklicensing
#sudo systemctl start adsklicensing


# VERIFY LINCENSE IS RUNNING

# INSTALL MAYA


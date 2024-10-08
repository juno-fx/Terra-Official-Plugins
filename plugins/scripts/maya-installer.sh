echo "Installing Autodesk Maya..."

temp_install_dir=$2/maya_installer

mkdir -p $temp_install_dir
mkdir -p $2

chmod -R 777 $temp_install_dir/
chmod -R 777 $2

cd /tmp

if [ "$DEV_APPS_DEBUG" = true ]
then
  echo "Dev Apps Debug is enabled - maya copied with docker"
else
  # download the installer
  wget -q -O /tmp/mayainstaller.tgz "$1"
fi

chmod +x /tmp/mayainstaller.tgz


tar -xvf /tmp/mayainstaller.tgz -C $temp_install_dir

chmod -R 777 $temp_install_dir/
chmod -R 777 $2

# check maya installer
ls -la $temp_install_dir


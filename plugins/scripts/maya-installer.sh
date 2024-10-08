echo "Installing Autodesk Maya..."
temp_install_dir=$2/maya_installer

mkdir -p $temp_install_dir
mkdir -p $2

chmod -R 777 $temp_install_dir/
chmod -R 777 $2
cd /
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


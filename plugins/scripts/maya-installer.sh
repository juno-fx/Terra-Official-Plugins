echo "Installing Autodesk Maya..."

temp_install_dir=/apps/maya_installer

mkdir -p $temp_install_dir
mkdir -p $2

cd /tmp

if [ "$DEV_APPS_DEBUG" = true ]
then
  echo "Dev Apps Debug is enabled - maya copied with docker"
else
  # download the installer
  wget -q -O /tmp/mayainstaller.tgz "$1"
fi

# check maya tmp
ls -la /tmp

tar xfvz /tmp/mayainstaller.tgz -C $temp_install_dir

# check maya installer
ls -la $temp_install_dir


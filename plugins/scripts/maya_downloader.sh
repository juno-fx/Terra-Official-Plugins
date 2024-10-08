# download maya from autodesk site

#INSTALL DEPS
echo "--------------------------------------------------------------"
echo "Download Maya installer"
echo "--------------------------------------------------------------"
temp_install_dir=$2/maya_installer

# we want to keep maya installers along the whole install process so we need to make sure we install in apps/temp dir
mkdir -p $temp_install_dir $2
chmod -R 777 $temp_install_dir $2

if [ "$DEV_APPS_DEBUG" = true ]
then
  echo "Dev Apps Debug is enabled - maya copied with docker"
else
  # download the installer
  wget -q -O /tmp/mayainstaller.tgz "$1"
fi

# extract the installer
echo "Extracting Maya installer and setup files"
tar -xvzf /tmp/mayainstaller.tgz -C $temp_install_dir > /dev/null
# check maya installer
ls -la $temp_install_dir
chmod -R 777 $temp_install_dir

echo "--------------------------------------------------------------"
echo "Extracting done."
echo "--------------------------------------------------------------"
# lets move to the next step


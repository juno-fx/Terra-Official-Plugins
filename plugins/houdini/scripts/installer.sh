
set -e

echo "Installing $VERSION - $DESTINATION"

echo "Setting up prequesites"
apt update
apt install bc wget unzip python3 python3-venv python3-pip -y
python3 -m venv venv
source venv/bin/activate
venv/bin/pip --version

venv/bin/pip  install requests
venv/bin/pip  install click


# store our current working dir
working_dir="$PWD"
echo $working_dir

# We need to pass export SIDEFX_CLIENT_ID=''; export SIDEFX_CLIENT_SECRET=''; export DEV_APPS_DEBUG=true to the scipt itself
export SIDEFX_CLIENT_ID=$CLIENT_ID
export SIDEFX_CLIENT_SECRET=$CLIENT_SECRET

# split our version/build values
echo "version"
echo $VERSION
export HOUDINI_VERSION="${VERSION%.*}"
export HOUDINI_BUILD="${VERSION##*.}"
INSTALL_DIR="$DESTINATION/$VERSION"

temp_folder="/tmp/apps_temp"
mkdir -p $temp_folder
mkdir -p "$temp_folder"/"$VERSION"
mkdir -p "$temp_folder"/"$VERSION"/installs
temp_folder_version="$temp_folder"/"$VERSION"

echo "Downloading Houdini $VERSION"
if [ "$DEV_APPS_DEBUG" = true ]
then
	echo "Dev Apps Debug is enabled"
  cp /tmp/houdini.tar.gz $temp_folder_version/houdini.tar.gz
  chmod +x $temp_folder_version/houdini.tar.gz
else
  venv/bin/python "$working_dir/sidefx_downloader.py" --version $HOUDINI_VERSION --build $HOUDINI_BUILD --key $SIDEFX_CLIENT_ID --secret $SIDEFX_CLIENT_SECRET --output $temp_folder_version
fi

echo "Extracting Houdini tar.gz"
chmod 777 $temp_folder_version/houdini.tar.gz
tar -xvf $temp_folder_version/houdini.tar.gz -C $temp_folder_version/installs > $temp_folder_version/houdini_extract.log
rm -rf $temp_folder_version/houdini.tar.gz
echo "Houdini.tar.gz extracted to $temp_folder_version/installs"

# get gcc version
files=( "${temp_folder_version}"/installs/*/ )
hou_installer_folder="${files[0]}"

echo "Installing Houdini... $INSTALL_DIR ..."

mkdir -p $DESTINATION
chmod -R 777 $DESTINATION
mkdir -p $INSTALL_DIR
chmod -R 777 $INSTALL_DIR
echo "Houdini Install Dir: $INSTALL_DIR"

# get license date from file
export $(cat $hou_installer_folder/houdini.install | grep 'LICENSE_DATE=' | tr -d '"')
echo "License Date:" $LICENSE_DATE


mkdir -p $DESTINATION/hq_server $DESTINATION/hq_client $DESTINATION/hqueue_shared
chmod -R 777 $DESTINATION/hq_server $DESTINATION/hq_client $DESTINATION/hqueue_shared

echo "Running Houdini Installer for $VERSION"

cd $hou_installer_folder
./houdini.install --auto-install --install-menus --install-sidefxlabs --sidefxlabs-dir $INSTALL_DIR --no-install-hfs-symlink --no-root-check \
--no-install-bin-symlink \
--no-install-license --accept-EULA $LICENSE_DATE \
--make-dir $INSTALL_DIR \
--install-dir $INSTALL_DIR  #> $DESTINATION/houdini_install.log

echo "Adding desktop files"
# app icon setup
cd $working_dir
cp -v ./assets/houdini.png $DESTINATION/

cd $DESTINATION
pwd
ls -la

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini FX $VERSION
Comment=SideFX Houdini software
Exec=vglrun -d /dev/dri/card0 $INSTALL_DIR/bin/houdinifx %F
Icon="$DESTINATION/houdini.png"
Terminal=false
Type=Application
Categories=X-Polaris" > $DESTINATION/houdinifx_$VERSION.desktop

echo "[Desktop Entry]
Version=$VERSION
Name=Houdini Core $VERSION
Comment=SideFX Houdini software
Exec=vglrun -d /dev/dri/card0 $INSTALL_DIR/bin/houdinicore %F
Icon="$DESTINATION/houdini.png"
Terminal=false
Type=Application
Categories=X-Polaris" > $DESTINATION/houdinicore_$VERSION.desktop

# set permission for desktop files and copy over to applications dir
chmod 644 $DESTINATION/houdinicore_$VERSION.desktop
chmod 644 $DESTINATION/houdinifx_$VERSION.desktop


cat $DESTINATION/*.desktop

echo "Desktop file created."
echo "Install Complete"
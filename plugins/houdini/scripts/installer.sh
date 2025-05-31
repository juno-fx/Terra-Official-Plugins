
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
export SESI_HOST="hlicense"
export houdini_install_version="$VERSION"
export houdini_install_dir="$DESTINATION/$VERSION"

temp_folder="/tmp/apps_temp"
mkdir -p $temp_folder
mkdir -p "$temp_folder"/"$houdini_install_version"
mkdir -p "$temp_folder"/"$houdini_install_version"/installs
temp_folder_version="$temp_folder"/"$houdini_install_version"

echo "Downloading Houdini $houdini_install_version"
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

echo "Installing Houdini... $houdini_install_dir ..."

chmod -R 777 $DESTINATION
mkdir -p $houdini_install_dir
chmod -R 777 $houdini_install_dir
echo "Houdini Install Dir: $houdini_install_dir"

# get license date from file
export $(cat $hou_installer_folder/houdini.install | grep 'LICENSE_DATE=' | tr -d '"')
echo "License Date:" $LICENSE_DATE


mkdir -p $DESTINATION/hq_server $DESTINATION/hq_client $DESTINATION/hqueue_shared
chmod -R 777 $DESTINATION/hq_server $DESTINATION/hq_client $DESTINATION/hqueue_shared

# --install-hqueue-client --hqueue-client-dir $DESTINATION/hq_client --hqueue-server-name "hq-server" --hqueue-client-user "polaris-render-node" \
# --install-hqueue-server --hqueue-server-dir $DESTINATION/hq_server --hqueue-shared-dir $DESTINATION/hqueue_shared --hqueue-server-port 45000 \
echo "Running Houdini Installer for $houdini_install_version"

cd $hou_installer_folder
./houdini.install --auto-install --install-menus --install-sidefxlabs --sidefxlabs-dir $houdini_install_dir --no-install-hfs-symlink --no-root-check \
--no-install-bin-symlink \
--license-server-name $SESI_HOST --no-install-license --accept-EULA $LICENSE_DATE \
--make-dir $houdini_install_dir \
--install-dir $houdini_install_dir  #> $DESTINATION/houdini_install.log


# save stuff from install
echo "Copying Houdini desktop files to $houdini_install_dir"
cp -r $HOME/.local/share/applications/sesi_*.desktop $DESTINATION/
echo "check copy desktop files"
ls -la $DESTINATION/


cd $DESTINATION
echo "Enter to $DESTINATION"
# rewrite categories for XDG-XFCE compatibility

for desktopfile in *.desktop;
do
  echo "Cleaning up $desktopfile"
  sed -i "s@Categories=.*@Categories=X-Polaris;@g" $desktopfile
done

echo "Create Houdini Version sh file $houdini_install_version"

cd $working_dir
runner_file=$houdini_install_dir/run_houdini_"$houdini_install_version".sh

cp -v $working_dir/houdini.sh $runner_file
sed -i "s@ROOT_APP@$houdini_install_dir@g" $runner_file
sed -i "s@APPVERSION@$HOUDINI_VERSION@g" $runner_file
sed -i "s@APPBUILD@$HOUDINI_BUILD@g" $runner_file
sed -i "s@APPSERVERHOST@$SESI_HOST@g" $runner_file
chmod +x $runner_file

# app icon setup
cp "./assets/houdini.png" "$houdini_install_dir/houdini.png"
cp "./assets/houdini.desktop" "$DESTINATION/houdini.desktop"
# replace our icon/exec placeholder strings with proper values
cd $DESTINATION
pwd
ls -la
sed -i -e "s@DESTINATION-PATH@$DESTINATION/houdini.sh@g" "$DESTINATION/houdini.desktop"
sed -i -e "s@ICON-PATH@DESTINATION/houdini.png@g" "$DESTINATION/houdini.desktop"
echo "Adding desktop file"
echo "Desktop file created."
chmod -R 777 "$DESTINATION/"
cat $DESTINATION/*.desktop

chmod -R 777 $DESTINATION/
echo "Install Complete"
# First part of prepping the actual files for the install

#INSTALL DEPS
echo "Install Maya Setup deps"
apt update -y
apt install alien dpkg-dev debhelper build-essential zlib1g-dev -y

temp_install_dir=$1/maya_installer

# lets convert rpms to debs, this takes TIME!
cd $temp_install_dir/install/Packages
alien -vc *.rpm > /dev/null

# lets list the installers
ls -la $temp_install_dir/install/Packages

# lets move to the next step
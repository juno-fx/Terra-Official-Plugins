# First part of prepping the actual files for the install

#INSTALL DEPS
echo "Install Maya Setup deps"
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt-get install software-properties-common -y
add-apt-repository universe -y
apt-get update -y
apt-get install apt-utils -y
apt-get install apt-clone -y
apt-get install -y --no-install-recommends alien dpkg-dev debhelper build-essential zlib1g-dev
echo "--------------------------------------------------------------"
temp_install_dir=$1/maya_installer

echo "Convert rpms to debs"
# lets convert rpms to debs, this takes TIME!
cd $temp_install_dir/install/Packages
#alien -vc *.rpm > /dev/null

alien -vc adlmapps29-29.0.2-0.x86_64.rpm
alien -vc adskflexnetclient-11.18.0-0.x86_64.rpm
alien -vc adsklicensing14.0.0.10163-0-0.x86_64.rpm
alien -vc Bifrost2025-2.10.0.0-2.10.0.0-1.x86_64.rpm
alien -vc Maya2025_64-2025.2-2237.x86_64.rpm
alien -vc LookdevX-1.5.0-2025.el8.x86_64.rpm
alien -vc MayaUSD2025-202406120659-f8eb6c1-0.29.0-1.x86_64.rpm

alien -vc AdskIdentityManager/adskidentitymanager1.11.10.1-1.x86_64.rpm

cd Licensing
alien -vc adlmapps29-29.0.2-0.x86_64.rpm
alien -vc adskflexnetclient-11.18.0-0.x86_64.rpm
alien -vc adskflexnetserverIPV6-11.19.4-1.x86_64.rpm
alien -vc adskidentitymanager1.11.10.1-1.x86_64.rpm
alien -vc adsklicensing14.0.0.10163-0-0.x86_64.rpm

echo "Check debs and move to next step"
# lets list the installers
ls -la $temp_install_dir/install/Packages/*.deb
echo "--------------------------------------------------------------"
echo "Converting rpms done."
echo "--------------------------------------------------------------"
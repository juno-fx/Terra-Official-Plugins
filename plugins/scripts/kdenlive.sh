SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "Switching to squashfs-root directory"
cd $SCRIPT_DIR/squashfs-root/
echo "Running kdenlive"
./AppRun

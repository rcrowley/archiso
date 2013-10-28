set -e -x

# Find the absolute pathname of the directory with this bootstrap.sh.
DIRNAME="$(cd "$(dirname "$0")" && pwd)"

# Clone archiso if we're not ourselves in a clone.
if [ "$(basename "$DIRNAME")" != "archiso" -a ! -d ".git" ]
then
    if [ ! -d "archiso" ]
    then
        pacman -S --needed --noconfirm "git"
        git clone "git://github.com/rcrowley/archiso.git" # git clone "git://projects.archlinux.org/archiso.git"
    fi
    exec sh "archiso/bootstrap.sh"
fi

# Remove temporary files on exit.
TMP="$(mktemp -d --tmpdir="$PWD")"
trap "rm -rf \"$TMP\"" EXIT INT QUIT TERM
cd "$TMP"

# Install dependencies for archiso/configs/{baseline,unattended}.
pacman -S --needed --noconfirm "arch-install-scripts" "make" "mkinitcpio-nfs-utils" "rsync" "squashfs-tools"
# pacman -S --needed --noconfirm "dosfstools" "lynx" # Required by configs/releng.

# Install this archiso.
make -C"$DIRNAME" install

# Configure archiso/configs/unattended to PXE boot and download its root
# filesystem via HTTP.
mkdir -p "work/root-image/usr/lib/initcpio/hooks" "work/root-image/usr/lib/initcpio/install"
cp "/usr/lib/initcpio/hooks/archiso_pxe_common" "work/root-image/usr/lib/initcpio/hooks"
cp "/usr/lib/initcpio/hooks/archiso_pxe_http" "work/root-image/usr/lib/initcpio/hooks"
cp "/usr/lib/initcpio/install/archiso_pxe_common" "work/root-image/usr/lib/initcpio/install"
cp "/usr/lib/initcpio/install/archiso_pxe_http" "work/root-image/usr/lib/initcpio/install"

# Build archiso and, by side-effect, the PXE tree.
sh "$DIRNAME/configs/unattended/build.sh" -v

# Upload the PXE tree for <https://github.com/rcrowley/puppet-virtualbox>.
if [ ! -L "work/iso/arch/arch" ]
then ln -s "." "work/iso/arch/arch"
fi
rsync -avz "work/iso/arch" "rcrowley.org":"var/www/"

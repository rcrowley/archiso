set -e -x

# Install dependencies for archiso/configs/baseline.
pacman -S --needed --noconfirm "arch-install-scripts" "git" "make" "mkinitcpio-nfs-utils" "squashfs-tools"
# pacman -S --needed --noconfigm "dosfstools" "lynx" # These are necessary for the configs/releng.

# Clone and install bleeding-edge archiso from Git.
if [ "$(basename "$(pwd)")" = "archiso" ]
then cd ".."
fi
if [ ! -d "archiso" ]
then git clone "git://projects.archlinux.org/archiso.git"
fi
make -C"archiso" install

# Configure archiso/configs/baseline to PXE boot and download its root
# filesystem via HTTP.
mkdir -p "work/root-image/usr/lib/initcpio/hooks" "work/root-image/usr/lib/initcpio/install"
cp "/usr/lib/initcpio/hooks/archiso_pxe_common" "work/root-image/usr/lib/initcpio/hooks"
cp "/usr/lib/initcpio/hooks/archiso_pxe_http" "work/root-image/usr/lib/initcpio/hooks"
cp "/usr/lib/initcpio/install/archiso_pxe_common" "work/root-image/usr/lib/initcpio/install"
cp "/usr/lib/initcpio/install/archiso_pxe_http" "work/root-image/usr/lib/initcpio/install"

# Build archiso and, by side-effect, the PXE tree.
archiso/configs/baseline/build.sh -v

# Upload the PXE tree.
scp -r "work/iso/arch" "rcrowley.org":"var/www/arch"

#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

rm -rf autoinstall-ISO/* squashfs-root
mkdir -p ./autoinstall-ISO/source-files

7z -y x ./ubuntu-*.iso -oautoinstall-ISO/source-files

mv  './autoinstall-ISO/source-files/[BOOT]' ./autoinstall-ISO/BOOT
cp assets/grub.cfg ./autoinstall-ISO/source-files/boot/grub/grub.cfg
cp -r assets/server ./autoinstall-ISO/source-files/

# Extract filesystem.squashfs
unsquashfs autoinstall-ISO/source-files/casper/filesystem.squashfs
mv squashfs-root autoinstall-ISO/extracted-filesystem

# Prepare chroot into filesystem.squashfs
mount -o bind /run/ autoinstall-ISO/extracted-filesystem/run
cp /etc/hosts autoinstall-ISO/extracted-filesystem/etc/
mount --bind /dev/ autoinstall-ISO/extracted-filesystem/dev

# Perform operations in chroot
chroot autoinstall-ISO/extracted-filesystem /bin/bash <<"EOT"
# Mount hardware devices
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

# Execute commands in chroot
apt update
apt install -y linux-headers-5.15.0-87-generic linux-image-5.15.0-87-generic
apt-mark hold linux-generic linux-image-generic linux-headers-generic
touch /custom-file

# Cleanup before existing chroot
apt-get autoremove
apt clean
apt-get clean
rm -rf /tmp/* ~/.bash_history

rm /var/lib/dbus/machine-id || true
rm /sbin/initctl || true
dpkg-divert --rename --remove /sbin/initctl || true

umount /proc
umount /sys
umount /dev/pts
EOT

# umount from chroot
umount autoinstall-ISO/extracted-filesystem/run
umount autoinstall-ISO/extracted-filesystem/dev

# Replace squashfs of liveiso
rm autoinstall-ISO/source-files/casper/filesystem.squashfs
rm autoinstall-ISO/source-files/casper/filesystem.squashfs.gpg
chmod +w autoinstall-ISO/source-files/casper/filesystem.manifest
chroot autoinstall-ISO/extracted-filesystem dpkg-query -W --showformat='${Package} ${Version}\n' > autoinstall-ISO/source-files/casper/filesystem.manifest
mksquashfs autoinstall-ISO/extracted-filesystem autoinstall-ISO/source-files/casper/filesystem.squashfs \
    -noappend \
    -comp xz \
    -wildcards \
    -e "proc/*" \
    -e "proc/.*" \
    -e "run/*" \
    -e "run/.*" \
    -e "tmp/*" \
    -e "tmp/.*" \
    -e "var/crash/*" \
    -e "var/crash/.*" \
    -e "swapfile" \
    -e "root/.bash_history" \
    -e "root/.cache" \
    -e "root/.wget-hsts" \
    -e "home/*/.bash_history" \
    -e "home/*/.cache" \
    -e "home/*/.wget-hsts"
printf "%s" "$(du -sx --block-size=1 autoinstall-ISO/extracted-filesystem | cut -f1)" > autoinstall-ISO/source-files/casper/filesystem.size
# Sign new squashfs
gpg --import assets/private.pgp
gpg --local-user 87E14F2F84A1F80728631F144350DE5909853EE0 --output autoinstall-ISO/source-files/casper/filesystem.squashfs.gpg --detach-sign autoinstall-ISO/source-files/casper/filesystem.squashfs

# To get information from base ISO use "xorriso -indev ubuntu-20.04.6-live-server-amd64.iso -report_el_torito as_mkisofs"
(
    cd ./autoinstall-ISO/source-files
    xorriso -as mkisofs -r \
        -V 'Ubuntu-Server 20.04.6 LTS amd64' \
        -o ../../custom-ubuntu-20.04.6-live-server-amd64.iso \
        -partition_offset 0 \
        --mbr-force-bootable \
        -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b ../BOOT/2-Boot-NoEmul.img \
        -appended_part_as_gpt \
        -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
        -c '/isolinux/boot.cat' \
        -b '/isolinux/isolinux.bin' \
        -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
        -eltorito-alt-boot \
        -e '--interval:appended_partition_2:::' \
        -no-emul-boot \
        .
)

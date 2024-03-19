#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

rm -rf autoinstall-ISO/* squashfs-root
mkdir -p ./autoinstall-ISO/source-disk

# Mount ISO to get files
mount --options loop,uid="${UID}",gid="$(id -g $UID)" "./ubuntu-20.04.6-live-server-amd64.iso" "${PWD}/autoinstall-ISO/source-disk"
rsync --info=progress2 "${PWD}/autoinstall-ISO/source-disk/" "${PWD}/autoinstall-ISO/source-files" \
    --delete \
    --recursive \
    --links \
    --chmod=u+rwX,g=rX,o=rX \
    --exclude="md5sum.txt" \
    --exclude="MD5SUMS" \
    --exclude=".disk/release_notes_url" \
    --exclude="/casper/filesystem.manifest" \
    --exclude="/casper/filesystem.size" \
    --exclude="/casper/filesystem.squashfs" \
    --exclude="/casper/filesystem.squashfs.gpg"


# Update grub and cloudinit
cp assets/grub.cfg ./autoinstall-ISO/source-files/boot/grub/grub.cfg
cp -r assets/server ./autoinstall-ISO/source-files/

# Extract filesystem.squashfs
unsquashfs autoinstall-ISO/source-disk/casper/filesystem.squashfs
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

# Umount ISO
umount "${PWD}/autoinstall-ISO/source-disk"

# To get information from base ISO use "xorriso -indev ubuntu-20.04.6-live-server-amd64.iso -report_el_torito as_mkisofs"
(
    cd ./autoinstall-ISO/source-files
    xorriso -as mkisofs \
        -r -J -joliet-long -l -iso-level 3 \
        -V 'Ubuntu-Server 20.04.6 LTS amd64' \
        -isohybrid-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt,zero_apm:'../../ubuntu-20.04.6-live-server-amd64.iso' \
        -partition_cyl_align on \
        -partition_offset 0 \
        -partition_hd_cyl 89 \
        -partition_sec_hd 32 \
        --mbr-force-bootable \
        -apm-block-size 2048 \
        -iso_mbr_part_type 0x00 \
        -c '/isolinux/boot.cat' \
        -b '/isolinux/isolinux.bin' \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e '/boot/grub/efi.img' \
        -no-emul-boot \
        -boot-load-size 8128 \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        -o ../../custom-ubuntu-20.04.6-live-server-amd64.iso \
        .
)

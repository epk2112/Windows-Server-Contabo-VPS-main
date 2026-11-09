#!/bin/bash
# Windows Server 2022 installer for Contabo VPS (run from the Debian 10 Live Rescue System)
# Downloads the Windows Server 2022 zip and the virtIO zip, extracts them,
# and uses whichever .iso is found inside each extracted folder.

WIN_ZIP_URL="https://huggingface.co/datasets/bongo2112/server-vps-windows-first-programs/resolve/main/windows_server_2022_january_2023.zip"
VIRTIO_ZIP_URL="https://huggingface.co/datasets/bongo2112/server-vps-windows-first-programs/resolve/main/virtio.zip"

apt update -y
apt install grub2 filezilla gparted wimtools unzip rsync wget -y

# Make sure nothing from a previous install is mounted, then wipe old signatures
umount /mnt 2>/dev/null
umount /root/windisk/winfile 2>/dev/null
umount /root/windisk 2>/dev/null
swapoff -a 2>/dev/null
wipefs -a /dev/sda 2>/dev/null

# Get the disk size in GB and convert to MB
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))

# Calculate partition size (25% of total size)
part_size_mb=$((disk_size_mb / 4))

# Create GPT partition table (this erases the old Windows installation)
parted /dev/sda --script -- mklabel gpt

# Create two partitions
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB $((2 * part_size_mb))MB

# Inform kernel of partition table changes
partprobe /dev/sda
sleep 30
partprobe /dev/sda
sleep 30
partprobe /dev/sda
sleep 30

# Format the partitions
mkfs.ntfs -f /dev/sda1
mkfs.ntfs -f /dev/sda2

echo "NTFS partitions created"

echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda

mount /dev/sda1 /mnt

# Prepare directory for the Windows disk
cd ~
mkdir -p windisk
mount /dev/sda2 windisk

grub-install --root-directory=/mnt /dev/sda

# Edit GRUB configuration
cd /mnt/boot/grub
cat <<EOF > grub.cfg
menuentry "windows installer" {
	insmod ntfs
	search --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF

cd /root/windisk
mkdir -p winfile win_extract virtio_extract

# ---------- Windows Server 2022 ----------
wget -c -O windows_server_2022.zip "$WIN_ZIP_URL" || { echo "Failed to download Windows zip"; exit 1; }
unzip -o windows_server_2022.zip -d win_extract || { echo "Failed to unzip Windows zip"; exit 1; }
rm -f windows_server_2022.zip

WIN_ISO=$(find win_extract -type f -iname '*.iso' | head -n 1)
if [ -z "$WIN_ISO" ]; then
    echo "No .iso file found inside the Windows zip"; exit 1
fi
echo "Using Windows ISO: $WIN_ISO"

mount -o loop "$WIN_ISO" winfile || { echo "Failed to mount Windows ISO"; exit 1; }
rsync -avh --progress winfile/ /mnt/
umount winfile

# ---------- VirtIO drivers ----------
wget -c -O virtio.zip "$VIRTIO_ZIP_URL" || { echo "Failed to download virtio zip"; exit 1; }
unzip -o virtio.zip -d virtio_extract || { echo "Failed to unzip virtio zip"; exit 1; }
rm -f virtio.zip

VIRTIO_ISO=$(find virtio_extract -type f -iname '*.iso' | head -n 1)
if [ -z "$VIRTIO_ISO" ]; then
    echo "No .iso file found inside the virtio zip"; exit 1
fi
echo "Using virtIO ISO: $VIRTIO_ISO"

mount -o loop "$VIRTIO_ISO" winfile || { echo "Failed to mount virtIO ISO"; exit 1; }
mkdir -p /mnt/sources/virtio
rsync -avh --progress winfile/ /mnt/sources/virtio/
umount winfile

# ---------- Inject virtIO drivers into the Windows setup image ----------
cd /mnt/sources
touch cmd.txt
echo 'add virtio /virtio_drivers' >> cmd.txt
wimlib-imagex update boot.wim 2 < cmd.txt

reboot

#!/usr/bin/env bash

set -x -euo pipefail

# Virtuelles Netzwerkkabel für qemu einrichten
ip link del tap0 || true
ip tuntap add dev tap0 mode tap
ip link set tap0 master br0
ip link set tap0 up

# Leeres Festplattenimage anlegen
rm -f disk.img
dd if=/dev/zero of=disk.img bs=1 seek=5G count=0
DEVICE=$(losetup -f --show disk.img)
trap "losetup -d $DEVICE" EXIT

qemu-system-x86_64 \
  -enable-kvm -cpu host -smp 2 \
  -m 4096 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_VARS.fd \
  -drive file=$DEVICE,if=ide,format=raw \
  -nic tap,ifname=tap0,model=virtio,script=no,downscript=no -boot n \
  -boot menu=on \
  -vga virtio -device virtio-tablet-pci \
  -audio driver=sdl,model=virtio

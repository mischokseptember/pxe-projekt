#!/usr/bin/env bash

set -x -euo pipefail

# Mit Altlasten aufräumen
# Liegt ein reines Debian noch auf der Platte?
if ! [ -e /var/lib/machines/debian.orig ]; then
  # Nein. Dann muss eins installiert werden.

  # Frisches Debian-System installieren, und zwar in das Verzeichnis
  # /var/lib/machines/debian.orig.tmp
  rm -rf /var/lib/machines/debian.orig.tmp
  debootstrap --include=systemd,dbus stable /var/lib/machines/debian.orig.tmp
  systemd-nspawn --resolv-conf=off -D /var/lib/machines/debian.orig.tmp -E PATH=$PATH -E DEBIAN_FRONTEND=noninteractive -- apt -y install nfs-kernel-server dnsmasq syslinux-efi pxelinux

  mv /var/lib/machines/debian.orig.tmp /var/lib/machines/debian.orig
fi

rm -rf /var/lib/machines/debian
cp --reflink=auto -a /var/lib/machines/debian.orig /var/lib/machines/debian

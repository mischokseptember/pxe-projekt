#!/usr/bin/env bash

set -x -euo pipefail

# Programmsuchpfad um die Ordner ergänzen, unter denen bei Debian Programme liegen
export PATH=$PATH:/usr/sbin:/usr/bin:/sbin:/bin

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

# Vorlagesystem klonen
rm -rf /var/lib/machines/debian
cp --reflink=auto -a /var/lib/machines/debian.orig /var/lib/machines/debian

# Root-Passwort festlegen
systemd-nspawn -D /var/lib/machines/debian -E PATH=$PATH -- bash -c "echo root:$ROOT_PASSWORD | chpasswd"

# Hostnamen festlegen
echo debian > /var/lib/machines/debian/etc/hostname

# Die Dateiserverauslieferungsapp (NFS) einrichten
cat > /var/lib/machines/debian/etc/exports <<EOF
/ 10.0.0.0/24(ro,no_subtree_check,crossmnt)
# Alles freigeben (ganz /), und zwar an alle Geräte aus dem 10.0.0.0/24-Netzwerk
EOF

# Netzwerkeinstellungen festlegen
cat > /var/lib/machines/debian/etc/network/interfaces.d/host0 <<EOF
auto host0
iface host0 inet static
  address 10.0.0.1/24
  gateway 10.0.0.254
EOF

# Einstellungen für dnsmasq, unsere DHCP-Server- und TFTP-Server-App in einem
tee /var/lib/machines/debian/etc/dnsmasq.conf <<EOF
# DNS-Server abschalten (nur DHCP und TFTP sind hier relevant):
port=0

# DHCP-Bereich festlegen: Adressen sollen im Bereich
# 10.0.0.100 bis 10.0.0.200 vergeben werden
dhcp-range=10.0.0.100,10.0.0.200,255.255.255.0

# Standardgateway mitteilen
dhcp-option=3,10.0.0.254

# Standard-DNS-Server mitteilen
dhcp-option=6,8.8.8.8

# Netzwerkboot -- zeige ein einfaches Menü
pxe-prompt="Press F8 for menu or proceed with default in", 1

# bietet pxelinux.0 für PXE via BIOS an
pxe-service=x86PC, "pxelinux.0", pxelinux
# bietet syslinux für PXE via UEFI an
pxe-service=X86-64_EFI, "syslinux", syslinux.efi
# Aufgrund eines Bugs muss die vorherige Zeile gedoppelt werden
pxe-service=X86-64_EFI, "syslinux", syslinux.efi

# auf TFTP-Anfragen reagieren
enable-tftp
tftp-root=/pxe
EOF

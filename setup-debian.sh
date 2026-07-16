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

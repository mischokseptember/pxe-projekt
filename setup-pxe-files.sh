#!/usr/bin/env bash

set -x -euo pipefail

# Sofern noch nicht früher geschehen, Client-System bauen
hash=$(sha256sum client.nix | cut -c1-8)
if [ ! -e client-tree-$hash ]; then
  nix-build -o client-tree-$hash '<nixpkgs/nixos>' -A config.system.build.pxeTree -I nixos-config=client.nix
fi

(
  cd /var/lib/machines/debian
  mkdir pxe
  cp -r \
    usr/lib/PXELINUX/pxelinux.0 \
    usr/lib/SYSLINUX.EFI/efi64/syslinux.efi \
    usr/lib/syslinux/modules/efi64/ldlinux.e64 \
    usr/lib/syslinux/modules/bios/ldlinux.c32 \
    "$OLDPWD"/client.nix \
    "$OLDPWD"/client-tree-$hash/* \
    pxe/
)

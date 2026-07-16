#!/usr/bin/env bash
# Beispielaufruf: ./run.sh eth0
# - Statt "eth0" muss der korrekte Name des physischen
#   Netzwerkinterface angegeben werden.

set -x -euo pipefail

# Name des physischen Kabelinterface
export PHYS_INTERFACE=${1:-enp0s31f6}

# Root-Passwort des Debian-Containers
# (Achtung: Darf keine Sonderzeichen enthalten)
# (Besser wäre es, Einloggen nur per SSH-Schlüssel zu erlauben)
export ROOT_PASSWORD=abc

./network.sh
./setup-debian.sh

#!/usr/bin/env bash
# Beispielaufruf: ./run.sh eth0
# - Statt "eth0" muss der korrekte Name des physischen
#   Netzwerkinterface angegeben werden.

set -x -euo pipefail

# Name des physischen Kabelinterface
export PHYS_INTERFACE=${1:-enp0s31f6}

./network.sh
./setup-debian.sh

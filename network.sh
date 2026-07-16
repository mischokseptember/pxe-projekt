#!/usr/bin/env bash

set -x -euo pipefail

# Mit Altlasten aufräumen
ip link del br0 2>/dev/null || true

# Virtuellen Switch anlegen
ip link add br0 type bridge
ip link set br0 up

# Echtes Kabelinterface in den Switch einstecken
ip link set $PHYS_INTERFACE master br0
ip link set $PHYS_INTERFACE up

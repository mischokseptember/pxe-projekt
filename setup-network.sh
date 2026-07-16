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

# Uns, dem Gastgebersystem, die IP-Adresse 10.0.0.254 geben,
# und Pakete aus Container(n) weiterleiten
ip addr add 10.0.0.254/24 dev br0
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -F
iptables -t nat -A POSTROUTING -j MASQUERADE -o wlan0

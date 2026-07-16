#!/usr/bin/env bash

set -x -euo pipefail

# Name des physischen Kabelinterface
export PHYS_INTERFACE=enp0s31f6

./network.sh

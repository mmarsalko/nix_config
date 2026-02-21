#!/usr/bin/env bash

set -e

SUBVOL="/home/matt-htpc/workspace/nextcloud"
SNAPDIR="/home/matt-htpc/workspace/nextcloud_snapshots"
DATE=$(date +%Y-%m-%d-%H%M)

mkdir -p $SNAPDIR

btrfs subvolume snapshot -r $SUBVOL $SNAPDIR/$DATE

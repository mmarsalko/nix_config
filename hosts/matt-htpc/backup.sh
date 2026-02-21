#!/usr/bin/env bash
set -e

export RESTIC_REPOSITORY="/media/nas/htpc-backup/restic"

SNAPDIR="/home/matt-htpc/workspace/nextcloud_snapshots"
LATEST=$(ls $SNAPDIR | sort | tail -n 1)

restic backup --insecure-no-password $SNAPDIR/$LATEST --tag nextcloud
# Prune old snapshots, but keep 2 per day, 7 days & 4 weeks
restic forget --keep-hourly 2 --keep-daily 7 --keep-weekly 4 --prune

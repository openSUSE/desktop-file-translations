#!/bin/bash
# This downloads all build artifacts in rsync-filter.txt in the specified project/repo/arch
# from the OBS backend at the specified rsync URL backend. This is only reachable from inside the
# OBS/openQA network and you'll also need to export the RSYNC_PASSWORD.

set -euo pipefail

project="openSUSE:Leap:15.0"
repository="standard"
arch="x86_64"
# ssh -L 8730:obs-backend.publish.opensuse.org:873 openqa.opensuse.org
backend="rsync://openqa@localhost:8730/opensuse-internal/"
dest="download"

mkdir -p "${dest}"

url="${backend}/build/${project}/${repository}/${arch}/"

rsync -a --prune-empty-dirs --delete-excluded --include-from rsync-filter.txt "$url" "${dest}"

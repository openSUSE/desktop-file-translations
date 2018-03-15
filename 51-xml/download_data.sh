#!/bin/bash
# This downloads all build artifacts matching file_patterns in the specified project/repo/arch
# from the OBS backend at the specified rsync URL backend. This is only reachable from inside the
# OBS/openQA network and you'll also need to export the RSYNC_PASSWORD.

set -euo pipefail

project="openSUSE:Leap:15.0"
repository="standard"
arch="x86_64"
# ssh -L 8730:obs-backend.publish.opensuse.org:873 openqa.opensuse.org
backend="rsync://openqa@localhost:8730/opensuse-internal/"
file_patterns='*-desktopfiles.tar.bz2 *-appstream.tar.bz2 *-polkitactions.tar.bz2 *-mimetypes.tar.bz2'

if [ $# -ne 1 ]; then
    echo "Usage: $0 <target dir>"
    exit 1
fi

dest="$1"

mkdir -p "${dest}"

full_dir_url="${backend}/build/${project}/${repository}/${arch}"
all_urls=""

for pattern in ${file_patterns}; do
    all_urls="${all_urls} ${full_dir_url}/"'*'"/${pattern}"
done

rsync -a $all_urls "${dest}"

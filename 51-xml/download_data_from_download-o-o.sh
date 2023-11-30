#!/bin/bash

set -o nounset

# This tool is space hungry!
# But solves the problem of extracting data from both Leap and SLES
# Basically if fetches ARCHIVES.gz (~2.5GB extracted) from currently developed Leap,
# and filters translatable files. Fetches binary rpms from the Leap oss repo, extracts individual files 
# and reconstructs tar.bz2 archives which were genrated in OBS.
#
# WARNING: Runtime can take a few hours (mostly downloading and later cpio extraction)
# and will consume around 10.2GB in `pwd`/download in total !!!

VERSION=15.6

# needed only for the tar.bz archive name
# https://serverfault.com/questions/557350/parse-an-rpm-name-into-its-components
function parse_rpm() { RPM=$1;B=${RPM##*/};B=${B%.rpm};A=${B##*.};B=${B%.*};R=${B##*-};B=${B%-*};V=${B##*-};B=${B%-*};N=$B;echo "$N"; }

if [ ! -f "ARCHIVES" ]; then
    wget https://download.opensuse.org/distribution/leap/$VERSION/repo/oss/ARCHIVES.gz
    gunzip ARCHIVES.GZ
fi

# limit it to only x86_64 and noarch
if [ ! -f "filtered_arches.txt" ]; then
    echo "Filtering only applicable arches"
    egrep "^\./x86_64|^\./noarch" ARCHIVES > filtered_arches.txt
fi

if [ ! -f "package_names.txt" ]; then
    echo "Fetching list of package names"
    grep "Name        :" filtered_arches.txt > package_names.txt
fi


if [ ! -f "matched_files.txt" ]; then
    echo "Looking up translatable file entries"
    egrep "\.desktop$|\.appdata\.xml$|usr/share/mime/*/.*xml$|polkit.*.policy$" filtered_arches.txt > matched_files.txt
fi

declare -A filelists

# ./noarch/grub2-powerpc-ieee1275-2.06-150500.29.8.1.noarch.rpm:    drwxr-xr-x    2 root    root                        0 Oct 11 12:15 /usr/share/grub2/powerpc-ieee1275
echo "Processing translatable file entries"
while read line; do
    entry_rpm=`echo $line | awk '{ print $1}' | sed -s "s/://" `
    entry_file=`echo $line | awk '{ print $NF}'`
    [ "${filelists[$entry_rpm]+abc}" ] && filelists[$entry_rpm]="${filelists[$entry_rpm]} $entry_file" || filelists[$entry_rpm]="$entry_file"
done < "matched_files.txt"

mkdir -p download
mkdir -p download/cache
echo "Getting binaries"
for key in "${!filelists[@]}"; do
    break
    entry_arch=`echo $key | awk -F "/" '{ print $2}'`
    entry_rpm=`echo $key | awk -F "/" '{ print $NF}' | sed -s "s/://"`
    entry_name=`grep $key package_names.txt | awk '{ print $NF }'`
    rpm_path=`echo $key | sed "s/^.//"`
    if [ ! -f "download/cache/$entry_rpm" ]; then
        wget -P download/cache https://download.opensuse.org/distribution/leap/15.6/repo/oss/$rpm_path
    fi
    for path in ${filelists[$key]}; do
        cachedir="`pwd`/download/cache"
        srpm=`rpm --query $cachedir/$entry_rpm  --queryformat "%{SOURCERPM} %{name}"`
        srpm_name=`parse_rpm $srpm`
        tgdir="`pwd`/download/extracted/$srpm_name"
        mkdir -p $tgdir
        pushd $tgdir > /dev/null
        rpm2cpio "$cachedir/$entry_rpm" | cpio -idv ".${path}" 
        popd
    done
done

echo "Creating archives"
tgdir="`pwd`/download/result"
for path in `pwd`/download/extracted/*; do
    pkg=`basename $path`
    if [ "$pkg" == "cache" ]; then
        continue
    fi
    pushd $path
    if [ ! -f "$tgdir/$pkg-desktopfiles.tar.bz2" ]; then
        # use grep to identify if some matching files were found, and only then continue
        find . -name "*.desktop" | grep . && find . -name "*.desktop" | tar -cf $tgdir/$pkg-desktopfiles.tar -T -
        if [ -f "$tgdir/$pkg-desktopfiles.tar" ]; then
            bzip2 $tgdir/$pkg-desktopfiles.tar
        fi
    fi
    if [ ! -f "$tgdir/$pkg-appstream.tar.bz2" ]; then
        find . -name "*.appdata.xml" | grep . && find . -name "*.appdata.xml" | tar -cf $tgdir/$pkg-appstream.tar -T -
        if  [ -f "$tgdir/$pkg-appstream.tar" ]; then
            bzip2 $tgdir/$pkg-appstream.tar
        fi
    fi
    if [ ! -f ".$tgdir/$pkg-polkitactions.tar.bz2" ]; then
        find . -name "*.policy" | grep . && find . -name "*.policy" | tar -cf $tgdir/$pkg-polkitactions.tar -T -
        if [ -f "$tgdir/$pkg-polkitactions.tar" ]; then
            bzip2 $tgdir/$pkg-polkitactions.tar
        fi
    fi
    if [ ! -f "$tgdir/$pkg-mimetypes.tar.bz2" ]; then
        find . -wholename "./usr/share/mime/*/*.xml" | grep . && find . -wholename "./usr/share/mime/*/*.xml" | tar -cf $tgdir/$pkg-mimetypes.tar -T -
        if [ -f "$tgdir/$pkg-mimetypes.tar" ]; then
            bzip2 $tgdir/$pkg-mimetypes.tar
        fi
    fi
    popd
done

# For cleanup during development
#rm -rf ARCHIVE.gz ARCHIVE filtered_arches.txt matched_files.txt download 

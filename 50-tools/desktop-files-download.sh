#!/bin/bash
#
# Copyright (c) 2016 SUSE LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

#
# This script is used to download new data for this Git repo from OBS
#
# It can be configured through "desktop-files-update.urls", and should be called
# from the root directory of the repo like
# "./50-tools/desktop-files-download.sh"
#

export LC_ALL=C

dir=`mktemp -d -t udf.XXXXXX`
cp -a 50-tools/desktop-files-* $dir
cd $dir
mkdir desktopfiles
cd desktopfiles
count=1
cat ../desktop-files-update.urls | while read url; do
   case "$url" in
    http*)
      ../desktop-files-list.sh "$url" $count
      count=$(($count+1))
      ;;
   esac
done

# Special cleanup rules written by coolo
rm -f *-MPlayer.desktopfiles
rm -f *-yast2-taotie.desktopfiles
rm -f sled-*
rm -rf *-susehelp.desktopfiles
for i in *-k*3*; do
   mv $i zz-$i
done

echo "Files have been downloaded into the directory '$dir'.";
exit 0;

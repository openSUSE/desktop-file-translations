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

urls[0]='https://api.opensuse.org/public/build/openSUSE:Leap:42.2/standard/x86_64'
urls[1]='https://api.opensuse.org/public/build/openSUSE:Leap:42.2:NonFree/standard/x86_64'

export LC_ALL=C

function desktop_files_list() {
  url=$1
  prefix=$2

  tfile=`mktemp`
  curl -k -s -n $url > $tfile
  echo "listing directory $url"
  config=`mktemp`
  grep '<entry' $tfile | cut -d\" -f2 | while read line; do
    #echo "listing $url/$line/$line.desktopfile"
    echo "url = \"$url/$line/$line.desktopfiles\"" >> "$config"
    echo "output = \"$prefix-$line.desktopfiles\"" >> "$config"
  done
  curl -s -k -n -K $config
  rm $tfile $config
  egrep -l '<status code="40.">' *.desktopfiles | xargs --no-run-if-empty rm

  rm -f $tfile
}

dir=`mktemp -d -t udf.XXXXXX`
podir=$PWD
cd $dir
mkdir desktopfiles
cd desktopfiles
count=1
for url in "${urls[@]}"; do
    desktop_files_list "$url" $count
    count=$(($count+1))
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

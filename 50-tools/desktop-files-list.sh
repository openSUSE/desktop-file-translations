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
# This script is a dependency of "desktop-files-update.sh", and should not be
# used directly
#

url=$1
prefix=$2

tfile=`mktemp`
curl -k -s -n $url > $tfile
if head $tfile | grep -q '<directory>'; then
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
  exit 0
fi

if head $tfile | grep -q '<binarylist>'; then
  grep '<binary filename=".*.desktopfiles"' $tfile | cut -d\" -f2 | while read line; do
    ofile=`mktemp`
    echo "fetching $url/$line"
    curl -k -s -n $url/$line -o $ofile
    if ! test -s $ofile; then
     rm $ofile
    fi
    if ! test -f $line; then
     mv $ofile $line
    fi
  done
fi

rm -f $tfile

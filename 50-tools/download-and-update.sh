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

branch=automation
cache=/tmp/desktop-file-cache
message='new data from upstream'

# Find repo directory
scriptdir="$(dirname $(realpath $0))"
cd $scriptdir/..

# Download and cache .desktop files
rm -r $cache
./50-tools/download-desktop-files.pl -j 4 $cache

while true; do

  # Update .po files
  git pull --rebase origin $branch
  ./50-tools/update-po-files.sh $cache
  if [ git diff-files --quiet HEAD -- ]; then
    echo "Data unchanged, nothing to commit."
    break
  fi
  git commit -a -m "${message}"

  # Try to push new data
  git fetch origin
  count="$(git rev-list --count --left-right origin/$branch...HEAD)"
  case "$count" in
    "0	"*)
      echo "We are ahead, pushing new data."
	    git push origin $branch
      break
	  ;;
    *)
      exit 1
      echo "We are behind, resetting to try again."
      git reset --hard HEAD~1
    ;;
  esac
done

# Clean up
rm -r $cache

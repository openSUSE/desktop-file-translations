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

function split_out()
{
  sed -e "s,^#:,# :," $1 | \
    msggrep -C -e "$3" -o - | \
    sed -e "s,^# :,#:," | msgcat -s -o $2 -

  sed -e "s,^#:,# :," $1 | \
    msggrep -v -C -e "$3" -o - | \
    sed -e "s,^# :,#:," | msgcat -s -o $1.new - && mv $1.new $1
}

function split_chars()
{
   list=`seq 26 | awk '{ printf "%c ", $1 + 96 }'; echo`
   base=`echo $1 | sed -e "s,\..*,,"`
   suffix=`echo $1 | sed -e "s,.*\.,.,"`
   for i in $list; do
      msggrep -o $base.$i$suffix -J -e "($i" $1
   done
}

split_out 50-pot/update-desktop-files.pot 50-pot/update-desktop-files-yast.pot "applications/YaST2"
split_out 50-pot/update-desktop-files.pot 50-pot/update-desktop-files-directories.pot "desktop-directories"
split_out 50-pot/update-desktop-files.pot 50-pot/update-desktop-files-screensavers.pot '[sS]creen[sS]aver'
split_out 50-pot/update-desktop-files.pot 50-pot/update-desktop-files-kde.pot "/kde"
split_out 50-pot/update-desktop-files-kde.pot 50-pot/update-desktop-files-kde-services.pot "/service"
split_out 50-pot/update-desktop-files.pot 50-pot/update-desktop-files-apps.pot "/share/applications/"
split_out 50-pot/update-desktop-files.pot 50-pot/update-desktop-files-mimelnk.pot share/mimelnk

#split_chars 50-pot/update-desktop-files.pot
#rm 50-pot/update-desktop-files.pot

#split_chars 50-pot/update-desktop-files-apps.pot
#rm 50-pot/update-desktop-files-apps.pot

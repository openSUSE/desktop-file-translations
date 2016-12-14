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

LL=$1
MY_LCN_CHECKOUT=.

[ -d po ] && {
  echo "*** \"po\" directory exists.  Move it away."
  exit 1
}
# rm -rf po
mkdir po
for file in $MY_LCN_CHECKOUT/$LL/po/update-desktop-files*.po; do
  lang=`echo $file | sed -e "s,/po/up.*,,; s,.*/,,"`
  echo $file
  test -d po/$lang || mkdir po/$lang
  # package valid files only
  msgfmt -o /dev/null --check $file || {
    rmdir po/$lang
    continue
  }
  # cp $file po/$lang/entries.po
  # instead of copying, convert to the old inline format
  msgattrib -o - --no-obsolete $file | awk '/^msgctxt/ {
body = 1
ctxt=gensub(/msgctxt \"(.+)\"/, "\\1", "g")
# Escape "&" in file name
#print "***** " ctxt
gsub(/&/, "\\\\&", ctxt)
#print "***** " ctxt
next
}
/^msgid/ && body == 1 {
sub(/msgid \"/, "&" ctxt ": ")
print
next
}
{print}
' > po/$lang/entries.po.new
  msgfmt po/$lang/entries.po.new -o po/$lang/entries.mo;
  msgunfmt --no-wrap po/$lang/entries.mo | \
          grep -v '^"[A-Z][^ ]*: ' | grep '[^\][\]n"' && exit 1
  rm po/$lang/entries.mo

  if test -f po/$lang/entries.po; then
    msgcat -o po/$lang/entries.po --use-first po/$lang/entries.po po/$lang/entries.po.new
    rm po/$lang/entries.po.new
  else
    mv po/$lang/entries.po.new po/$lang/entries.po
  fi

done

msgfmt --verbose -o po/$lang/desktop_translations.mo po/$lang/entries.po
echo "*** po/$lang/desktop_translations.mo done."

exit 0

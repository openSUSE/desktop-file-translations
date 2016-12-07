#!/bin/bash

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


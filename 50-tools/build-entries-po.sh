#!/bin/bash

rm -rf po
mkdir po
for file in */update-desktop-files*.po; do
  lang=`echo $file | sed -e "s,/up.*,,; s,.*/,,"`
  echo $file
  test -d po/$lang || mkdir po/$lang
  # package valid files only
  msgfmt -o /dev/null --check $file || {
    rmdir po/$lang
    continue
  }
  # cp $file po/$lang/entries.po
  # instead of copying, convert to the old inline format
  # with the first awk, filter "\n", "\\ ", and "\ " in translations
  # (msgfilter does not work for me in this case)
  msgattrib -o - --width=1000 --no-obsolete $file | awk '/^msgctxt/ {
  body = 1;print;next}
body == 1 {
  sub(/\\n/, " ")
  sub(/\\\\ /, " ")
  sub(/\\ /, " ")
  print;next}
{print}' | awk '/^msgctxt/ {
  body = 1
  ctxt=gensub(/msgctxt \"(.+)\"/, "\\1", "g")
  gsub(/&/, "\\\\&", ctxt)
  next}
/^msgid/ && body == 1 {
  sub(/msgid \"/, "&" ctxt ": ")
  print
  next}
{print}
' > po/$lang/entries.po.new
  msgfmt po/$lang/entries.po.new -o po/$lang/entries.mo || exit
  # *-conflicts files are often empty; thus continue and avoid a
  # confusing shell error message
  [ -f po/$lang/entries.mo ] || continue
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

exit 0

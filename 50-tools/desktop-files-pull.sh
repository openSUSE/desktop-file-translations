#!/bin/bash

langs="af ar az be bg bn br bs ca cs cy da de el en_GB en_US eo es et eu fa"
langs="$langs fi fr fy ga gl gu he hi hr hu id is it"
langs="$langs ja ka km ko ku lo lt lv mk mn mr ms mt nb nds nl nn nso pa pl pt"
langs="$langs pt_BR ro ru rw se si sk sl sr sr@latin sv"
langs="$langs ta tg th tr tt uk uz vi ven wa xh zh_CN zh_TW zu"

export LC_ALL=C 

rm -rf pot po
mkdir pot
perl ./desktop-files-extract.pl > pot/entries.pot
msguniq --use-first -s -o pot/entries.pot pot/entries.pot
# this PREFIX magic is based on the assumption that -s sorts by msgid
sed -i -e 's,PREFIX.-,,' pot/entries.pot
msguniq --use-first -s -o pot/entries.pot pot/entries.pot

mkdir po
for i in $langs; do
  mkdir po/$i
  perl ./desktop-files-extract.pl $i > "po/$i/entries.po"
  msguniq --use-first --no-wrap -s -o "po/$i/entries.po" "po/$i/entries.po"
  sed -i -e 's,PREFIX.-,,' "po/$i/entries.po"
  sed -i -e 's,msgstr "",msgstr "NADA",' "po/$i/entries.po"
  msguniq --use-first --no-wrap -s -o "po/$i/entries.po" "po/$i/entries.po"
  sed -i -e 's,msgstr "NADA",msgstr "",' "po/$i/entries.po"
done

#
# check format
#
find po -name \*.po | while read i ; do
  msgfmt -o /dev/null --check-format "$i" || true
done


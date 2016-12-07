#!/bin/bash
# call ./50-tools/desktop-files-update.sh [LL] [svn]

export LC_ALL=C

# test -n "$lang" || lang={$(echo ?? ??_?? | sed 's/ /,/g')}
podir=$PWD
lang=$1
test -n "$lang" || lang="*"
svn=${2:-true}
# if non-empty, only pull pot files
pull_only=$3
init=$4

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
# removing nonsense
rm -f *-MPlayer.desktopfiles
rm -f *-yast2-taotie.desktopfiles
rm -f sled-*
rm -rf *-susehelp.desktopfiles
for i in *-k*3*; do
   mv $i zz-$i
done
#tar xf ~coolo/df.tar.bz2
cd ..

./desktop-files-pull.sh

#avoid loosing messages due some build service oopses
#msgcat --use-first -o pot/entries.pot pot/entries.pot $podir/50-pot/update-desktop-fil*.pot
msgmerge -s -o $podir/50-pot/update-desktop-files.pot pot/entries.pot pot/entries.pot
pushd $podir
./50-tools/desktop-files-split.sh
if [ -n "$pull_only" ]; then
  echo "*** pot files updated"
  exit 0
fi
if [ "$svn" = svn ]; then
  $svn ci -mupdate ./50-pot/update-desktop-files*.pot
fi
# enable once 13.1 is frozen
#exit 0
potlist=`cd 50-pot && ls -1 update-desktop-files*.pot | sed -e 's,.pot,,'`
popd
cd po
incorrect=0
svnlangs=`cd $podir && ls -1 */po/update-desktop-files*.po`
for i in $svnlangs; do
   i=`dirname $i | sed -e "s,/po,,"`
   if ! test -f $i/entries.po; then
      echo "Language $i is not collected"
      incorrect=1
   fi
done

if test "$incorrect" = 1; then
  exit 1
fi

:> desktop.log
for i in $lang/entries.po; do
      echo $i
      ilang=`echo $i | sed -e "s,/.*,,"`
      opodir=$podir/$ilang/po
      ofile=$opodir/update-desktop-files-all.$ilang.po
      # skip if there is no corresponing file in lcn
      [ -d $ilang ] || {
        echo "skipping \"$ilang\"; does not exist in lcn"
        continue
      }
      # 'svn up' as late, and 'svn ci' as early as possible to avoid
      # conflicts with active translators
      $svn up $opodir
      for f in $potlist; do
        msgcat --no-wrap $podir/$ilang/po/$f.$ilang.po | \
          sed -e 's,msgid "",msgid "HEADER",' | \
          msggrep -K -E -e 'HEADER' - | \
          sed -e "s,HEADER,," > $f.header
      done
      # create update-desktop-files*po files (initializing)
      if [ -n "$init" ]; then
        [ -f $podir/head-info.$ilang.po ] \
          || { echo "template missing: $podir/head-info.$ilang.po"; exit 1; }
        for f in $podir/50-pot/update-desktop-files*.pot; do
          pof=${f##*/}; pof=${pof%pot}$ilang.po
          [ -f $podir/$ilang/po/$pof ] \
            || cp $podir/head-info.$ilang.po $podir/$ilang/po/$pof
        done
      fi
      # use --force-po otherwise initializing fails
      msgcat --force-po --use-first -o - \
        $podir/$ilang/po/update-desktop-files*.$lang.po \
        | msgattrib --force-po --translated --no-fuzzy -s -o $ofile
      msgfmt --check -o /dev/null $ofile || {
        echo "broken $ofile" | tee -a desktop.log
        continue
      }
      if false; then # just a test
      msgcat --no-wrap $ofile | sed -e 's,msgstr "",msgstr "EMPTY",' | \
        msggrep -T -E -e 'EMPTY' --invert-match - > $ofile.2 && mv $ofile.2 $ofile
      msgcat --no-wrap $i | sed -e 's,msgstr "",msgstr "EMPTY",' | \
        msggrep -T -E -e 'EMPTY' --invert-match - > $i.2 && mv $i.2 $i
      fi
      msgcat --more-than=1 -o - $i $ofile | msgattrib --only-fuzzy --no-wrap |\
	   sed -e 's,#-#-#-#-#  update-desktop-files-all.*,SVN:\\n\",; s,#-#-#-#-#  entries.*,Packages:\\n\",' |\
	   msgcat -s -o $podir/$ilang/po/update-desktop-files-conflicts.$ilang.po  -
      msgcat -o new.po --use-first $i $ofile
      msgmerge -s -C $ofile -o new.po new.po new.po
      for f in $potlist; do
         msgmerge --previous -s -o - new.po $podir/50-pot/$f.pot | LC_ALL=C grep -v '^#~' | uniq | \
            msgcat -s -o $podir/$ilang/po/$f.$ilang.po  --use-first $f.header -
         rm $f.header
         msgmerge --previous -s -o $podir/$ilang/po/$f.$ilang.po $podir/$ilang/po/$f.$ilang.po $podir/50-pot/$f.pot
         echo $ilang/po/$f.$ilang.po
      done
      rm $ofile
      $svn add $opodir/update-desktop-files*.po
      $svn ci -mupdate $opodir/update-desktop-files*.po
done

echo $dir
cat desktop.log

exit 0

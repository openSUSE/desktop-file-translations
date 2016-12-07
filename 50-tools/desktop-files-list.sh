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

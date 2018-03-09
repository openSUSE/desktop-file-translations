#!/bin/bash

if ! test -d 50-tools ; then
	cd ..
fi
for POT in 50-pot/*.pot ; do
	POT_BASE=${POT#50-pot}
	POT_BASE=${POT_BASE%.pot}
	for PO in */$POT_BASE.po ; do
		LNG=${PO%/*}
		if msgmerge --previous --lang=${LNG%.po} $PO $POT -o $PO.new ; then
			mv $PO.new $PO
		fi
	done
done

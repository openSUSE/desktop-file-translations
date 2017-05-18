#!/bin/bash
set -euo pipefail

# die: Echo arguments to stderr and exit with 1
die() { echo "$@" 1>&2 ; exit 1; }
# Clear the current line and go back to the beginning
line_clear_back_home() { printf '\r                                                                                                                   \r'; }

if [ $# -ne 1 ]; then
	echo "Usage: $0 <directory with archives containing translations>"
	exit 1
fi

if [ ! -d "$1" ]; then
	echo "Directory does not exist"
	exit 1
fi

# Dir with stripped PO files
outputdir="$(dirname "$(realpath "$0")")/output"
# Dir with downloaded translation files (okular-appstream.tar.bz2 etc.)
inputdir="$(realpath "$1")"
# Dir with directories for each lang, containing *.po files for weblate
resultdir="$(dirname "$(realpath "$0")")/.."
# Create temporary directory for merging POs
tmpdir=$(mktemp -d) || die "Could not create temporary directory"
# Remove it on exit
trap rm\ -rf\ "${tmpdir}" EXIT

# TODO, is this correct?
langs="af ar az be bg bn br bs ca cs cy da de el en_GB en_US eo es et eu fa"
langs="$langs fi fr fy ga gl gu he hi hr hu id is it"
langs="$langs ja ka km ko ku lo lt lv mk mn mr ms mt nb nds nl nn nso pa pl pt"
langs="$langs pt_BR ro ru rw se si sk sl sr sr@latin sv"
langs="$langs ta tg th tr tt uk uz vi ven wa xh zh_CN zh_TW zu"

printf "Cleaning up old results..."
if ! rm -rf "${outputdir:?}"/*; then
	printf " Failed!"
	exit 1
fi

printf ' Done!\n'

echo "Generating new POT and PO files... "

for archive in "${inputdir}"/*; do
        printf "%s" "${archive}"
	if ! python3 tar2po/tar2po.py "${archive}" "${outputdir}"; then
		echo "Failed: ${archive}"
	fi
        line_clear_back_home
done

echo 'Done!'

echo "Cleaning up POT files... "
pushd "${outputdir}" > /dev/null
for potfile in *.pot; do
	printf "%s" "${potfile}"
	msguniq --use-first "${potfile}" > "${tmpdir}"/"${potfile}"
	mv "${tmpdir}"/"${potfile}" "${potfile}"
	line_clear_back_home
done
popd > /dev/null

echo 'Done!'

echo "Merging with existing PO files... "

for lang in $langs; do
        [ -d "${outputdir}"/"${lang}" ] || continue
	pushd "${outputdir}"/"${lang}" > /dev/null
	for pofile in *; do
		printf "%s %s" "${lang}" "${pofile}"
		msguniq --use-first "${pofile}" > "${tmpdir}"/"${pofile}"
		msgmerge -q "${tmpdir}"/"${pofile}" "../${pofile%%\.po}.pot" > "${pofile}"
		if [ -e "${resultdir}"/"${lang}"/"${pofile}" ]; then
			# PO-file exists, merge.
			msgmerge -q "${resultdir}"/"${lang}"/"${pofile}" "${pofile}" > "${tmpdir}"/"${pofile}"
			mv "${tmpdir}"/"${pofile}" "${resultdir}"/"${lang}"/"${pofile}"
		else
			# Does not exist yet, just copy
			mkdir -p "${resultdir}"/"${lang}"
			cp "${pofile}" "${resultdir}"/"${lang}"/"${pofile}"
		fi
		line_clear_back_home
	done
	popd > /dev/null
done

echo 'Done!'

echo "Copying over POT files... "
cp "${outputdir}"/*.pot "../50-pot/"

echo 'Done!'

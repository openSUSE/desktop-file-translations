New XML file translations mechanism
===================================

This directory contains scripts that generate gettext files from desktop files,
polkit actions, appstream metainfo and mimetype info.  

Design
------

The tar2po python subproject takes .tar archives and generates POT and PO files from
the files contained withhin, based on predefined rules on naming and parsing.

The generated files then can be used as a source for new translations and
translation updates. The generate_and_merge_pos.sh script takes care of that.

Workflow
--------

To update the PO and POT files in the repo, you need direct access to the openSUSE
Open Build Service rsync backend. download_data.sh then downloads all needed .tar
archives needed. generate_and_merge_pos.sh then invokes tar2po for those and then
merges the file back into the source PO and POT files used by weblate.
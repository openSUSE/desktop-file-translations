# Desktop File Translations

  A collection of `.po` files with translations for `.desktop` files in openSUSE
  and the tools to maintain them.

## Workflow

  The whole process has three parts, two smaller ones that are maintained
  as packages in [OBS](https://build.opensuse.org/), and a big one that connects
  everything, here in this repository.

  1. [update-desktop-files](https://build.opensuse.org/package/show/openSUSE:Factory/update-desktop-files):
     All `.desktop` files are collected from packages in OBS during the build
     process by the `brp-trim-desktop.sh` script. During this process the
     translations are stripped from the `.desktop` files and placed in a
     standard location, in slightly compressed form, to make them easy to
     collect through the OBS API for further processing.

  2. [desktop-file-translations](https://github.com/openSUSE/desktop-file-translations):
     The `.po` files in the GitHub repository are regularly updated by running
     the tools under `51-xml/download_data.sh` or newer `51-xml/download_data_from_download-o-o.sh` and `51-xml/generate_and_merge_pos.sh`
     scripts and then committing the results. The first script fetches the
     compressed `.desktop` files from the OBS API, and the second turns them
     into `.po` files, and merges the results into the already existing `.po`
     files in the repository.
     See [51-xml/README.md](https://github.com/openSUSE/desktop-file-translations/blob/master/51-xml/README.md) for details.

  3. [desktop-translations](https://build.opensuse.org/package/show/X11:common:Factory/desktop-translations):
     This package contains a `_service` file referring to the
     `desktop-file-translations` GitHub repository, and uses the script
     `50-tools/build-entries-po.sh` to turn the `.po` files from the repository
     into `entries.po` files that can be installed with openSUSE.

## Updating the .po files automatically

The `.po` files in this repository need to be updated in regular intervals, this
process can be automated with the files in `51-xml/`. Read the file [README.md](https://github.com/openSUSE/desktop-file-translations/blob/master/51-xml/README.md):
contained within for instructions.

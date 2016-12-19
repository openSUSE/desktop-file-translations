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
     the `download-desktop-files.sh` and `update-po-files.sh` scripts manually
     and then committing the results. The first script fetches the compressed
     `.desktop` files from the OBS API, and the second turns them into `.po`
     files, and merges the results into the already existing `.po` files in the
     repository.

  3. [desktop-translations](https://build.opensuse.org/package/show/X11:common:Factory/desktop-translations):
     This package contains a `_service` file referring to the
     `desktop-file-translations` GitHub repository, and uses the script
     `50-tools/build-entries-po.sh` to turn the `.po` files from the repository
     into `.mo` files that can be installed with openSUSE.

## Updating the .po files

The `.po` files in this repository need to be updated manually in regular
intervals. You can start this process by cloning the repository.
```
$ git clone git@github.com:openSUSE/desktop-file-translations.git
```
Next you'll have to run the `download-desktop-files.sh` and `update-po-files.sh`
scripts, which will take some time, so go grab a cup of tea.
```
$ cd desktop-file-translations
$ ./50-tools/download-desktop-files.sh /tmp/some-download-directory
$ ./50-tools/update-po-files.sh /tmp/some-download-directory
$ rm -rf /tmp/some-download-directory
```
The `.po` files should now be updated, but the changes have not been committed
yet. You can use your normal Git workflow to resolve any merge conflicts that
might have been created while you were waiting for the scripts to finish.
```
$ git commit -a -m 'updated .po files with new data from OBS'
$ git push origin master
```
Or just send a pull request on GitHub.

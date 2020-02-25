# New XML file translations mechanism

  This directory contains scripts that generate gettext files from desktop
  files, polkit actions, appstream metainfo and mimetype info.

## Design

  The `tar2po` python subproject takes .tar archives and generates POT and PO
  files from the files contained withhin, based on predefined rules on naming
  and parsing.

  The generated files then can be used as a source for new translations and
  translation updates. The `generate_and_merge_pos.sh` script takes care of that.

## Workflow

  To update the PO and POT files in the repo, you need direct access to the
  openSUSE Open Build Service rsync backend. `download_data.sh` then downloads all
  needed .tar archives needed. `generate_and_merge_pos.sh` then invokes `tar2po` for
  those and then merges the file back into the source PO and POT files used by
  [Weblate](https://l10n.opensuse.org/projects/desktop-file-translations/).

## Step by step

  1. Check `download_data.sh`. If needed, update `project` variable.

  2. To save thousands of OBS API queries, tools depend on
     `obs-backend.publish.opensuse.org` from the **openSUSE openQA** infrastructure.

     To reach this server via rsync, you need to use a ssh tunnel to
     `openqa.opensuse.org`.

     `openqa.opensuse.org` is currently accessible through a proxy from inside
     `suse.de` intranet. `suse.de` intranet is accessible by *SUSE employees only*.

     There is a plan to migrate openQA infrastructure to openSUSE Heroes VPN, so
     in future, you will need Heroes account. But it does not work yet.

     1. Have a suse.de account (SUSE employees only)

     2. Ask *Oliver Kurz* for ssh access to `openqa.opensuse.org` (you need to send
        your login and a public key)

     3. Get into `openqa.opensuse.org` and establish rsync proxy:

        ```shell
        ssh -v -o "HostName proxy-opensuse.suse.de" -o "Port 2215" -L 8730:obs-backend.publish.opensuse.org:873 openqa.opensuse.org
        ```

        Alternatively, you can use .ssh/config:
        ```
        Host                 openqa.opensuse.org
        HostName             proxy-opensuse.suse.de
        Port                 2215
        ```
        and
        ```shell
        ssh -v -L 8730:obs-backend.publish.opensuse.org:873 openqa.opensuse.org
        ```

     4. Know the rsync server password:
        ```shell
        grep PASS /opt/openqa-scripts/openqa-iso-sync
        ```

3. `./download_data.sh`

It will create download subdirectory and download output of all builds in the project.

4. `./generate_and_merge_pos.sh download`

It will merge strings into pot files.

5. `git commit ; git push`

   (You may need to remove invalid en_US translation.)

6. Continue with the process described in [../README.md](https://github.com/openSUSE/desktop-file-translations/blob/master/README.md)

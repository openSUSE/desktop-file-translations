#
# Copyright (c) 2017 SUSE Linux GmbH
#
# This file is part of tar2po.
#
# tar2po is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# tar2po is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with tar2po. If not, see <http://www.gnu.org/licenses/>.

"""
This file parses XML files uses for appstream metadata,
polkit actions and mineinfo and generates PO and POT files.
"""

from datetime import datetime
import sys
import os
import re
import tarfile
from lxml import etree as xml
from desktop_handler import extractDesktopLangInfo
from xml_handler import extractXMLLangInfo

# Assigns each file type regexes that match the full file path
# Keep in sync with brp-trim-translations.sh in update-desktop-files
PATH_PATTERNS = {'appstream':
                 [re.compile("/usr/share/metainfo/.+\\.xml"),
                  re.compile("/usr/share/appdata/.+\\.xml")],
                 'polkitaction':
                 [re.compile("/usr/share/polkit-1/actions/.+\\.policy")],
                 "mimeinfo":
                 [re.compile("/usr/share/mime/.+\\.xml")],
                 "desktopfile":
                 [re.compile("/.*/.+\\.desktop"),
                  re.compile("/.*/.+\\.directory")]
                 }

# Assigns each file type a handler
FILETYPE_HANDLERS = {'appstream': extractXMLLangInfo,
                     'polkitaction': extractXMLLangInfo,
                     'mimeinfo': extractXMLLangInfo,
                     'desktopfile': extractDesktopLangInfo
                     }

# For each basename (of a PO/POT file) this contains various regexes to match the file path.
FILENAME_PATTERNS = {'update-desktop-files-yast':
                     [
                         # Not YaST2/ to also pick up YaST.desktop
                         re.compile("/usr/share/applications/YaST.*\\.desktop")
                     ],
                     'update-desktop-files-directories':
                     [
                         re.compile("/usr/share/desktop-directories/.*\\.directory")
                     ],
                     'update-desktop-files-screensavers':
                     [
                         re.compile("/usr/share/applications/[sS]creen[sS]aver.*\\.desktop")
                     ],
                     'update-desktop-files-kde-services':  # Comes before -kde -> higher priority
                     [
                         re.compile("/usr/share/kde.*/services/\\.desktop")
                     ],
                     'update-desktop-files-kde':
                     [
                         re.compile("/usr/share/kde.*\\.desktop")
                     ],
                     'update-desktop-files':
                     [
                         re.compile("/usr/share/applications/.*\\.desktop")
                     ],
                     'polkitactions-freedesktop':
                     [
                         re.compile("/usr/share/polkit-1/actions/org\\.freedesktop.*\\.policy")
                     ],
                     }


def getFileType(filepath):
    """
    Based on the filepath, return the type of the file.
    The specification is given by the path_patterns global.
    Returns None if not found.
    """

    for type in PATH_PATTERNS:
        for pattern in PATH_PATTERNS[type]:
            if pattern.match(filepath):
                return type

    return None


def writeGettextFiles(files):
    """
    @param files: dict of filenames -> {'header': header, 'content': content}

    Writes header to file if file does not yet exist and appends content to file.
    """
    for name, filecontent in files.items():
        partcount = name.count('/')
        if partcount == 1:
            # Create directory first
            try:
                os.mkdir(name.split('/')[0])
            except FileExistsError as e:
                pass
        elif partcount != 0:
            print("Invalid file name '{}'".format(name))
            continue

        if not os.path.isfile(name):
            with open(name, "w") as file:
                file.write(filecontent['header'])

        with open(name, "a") as file:
            file.write(filecontent['content'])


def gettextQuote(string):
    """
    @returns quoted string for use in gettext PO(T) files.
    """

    # TODO: Handle newline, tab, some unicode (?)
    return '"{}"'.format(string.replace('"', '\\"'))


def gettextDateTimeUTC(when):
    """
    Formats when to be used in PO headers.
    """

    return when.strftime("%Y-%m-%d %H:%M+0000")


def gettextFilename(translation, ctxt, type):
    """
    Returns the basename of the gettext PO/POT file that should contain the
    translation translation with context ctxt of type type.
    It searches through FILENAME_PATTERNS and if it does not find a match,
    return the type as a fallback.
    """

    for filename, patterns in FILENAME_PATTERNS.items():
        for pattern in patterns:
            if pattern.match(translation['file']):
                return filename

    return type


def generateGettextFiles(lang_info, type, timestamp=datetime.utcnow()):
    """
    Gets output of extractXMLLangInfo (lang_info),
    returns dict of filenames and (header, content that needs to be appended).
    type is the type of the files the lang_info is extracted from.
    """

    files = {}
    for ctxt, value in lang_info.items():
        basename = gettextFilename(value, ctxt, type)
        pot_filename = basename + ".pot"
        if pot_filename not in files:
            header = """msgid ""
msgstr ""
"Project-Id-Version: tar2po\\n"
"POT-Creation-Date: {}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"\n\n""".format(gettextDateTimeUTC(timestamp))
            files[pot_filename] = {'header': header, 'content': ""}

        translation_header = "#: {}:{}\n".format(value['file'], value['line'])
        translation_header += "msgctxt {}\n".format(gettextQuote(ctxt))
        translation_header += "msgid {}\n".format(gettextQuote(value['values']['']))

        files[pot_filename]['content'] += translation_header + "msgstr \"\"\n\n"

        for lang, translation in value["values"].items():
            if lang == "":
                continue

            po_filename = lang + "/" + basename + ".po"
            if po_filename not in files:
                header = """msgid ""
msgstr ""
"Project-Id-Version: tar2po\\n"
"POT-Creation-Date: {}\\n"
"PO-Revision-Date: {}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"\n\n""".format(gettextDateTimeUTC(timestamp),
                                                   gettextDateTimeUTC(timestamp))
                files[po_filename] = {'header': header, 'content': ""}

            files[po_filename]['content'] += translation_header + "msgstr {}\n\n".format(gettextQuote(translation))

    return files


def processTarFile(filepath, timestamp=datetime.utcnow()):
    """
    filepath is the path to a tar file containing files to be processed.
    Returns dict of filenames and content that needs to be appended
    """
    with tarfile.open(filepath) as tar:
        gettext_output_all = {}
        for tar_file in tar:
            if not tar_file.isfile():
                continue

            # Make path absolute, if not already
            tar_file_path = tar_file.name if tar_file.name[0] == '/' else ('/' + tar_file.name)
            tar_file_type = getFileType(tar_file_path)
            if tar_file_type is None:
                print("Warning: Don't know how to handle {}".format(tar_file_path))
                continue

            try:
                lang_info = FILETYPE_HANDLERS[tar_file_type](tar.extractfile(tar_file), tar_file_path, tar_file_type)
            except Exception as e:
                print("Could not extract lang info from {}: {}".format(tar_file_path, e))
                continue

            gettext_output_file = generateGettextFiles(lang_info, tar_file_type, timestamp)

            for k, v in gettext_output_file.items():
                if k in gettext_output_all:
                    gettext_output_all[k]['content'] += v['content']
                else:
                    gettext_output_all[k] = v

        return gettext_output_all


def main(args):
    if len(args) != 3:
        print("Usage: {} <tar file> <outputdir>".format(args[0]))
        return 1

    # Secret option to generate test case output (raw dict with fixed timestamp)
    if args[1] == "--test":
        print(processTarFile(args[2], datetime.fromtimestamp(0)))
    else:
        os.chdir(args[2])
        writeGettextFiles(processTarFile(args[1]))


if __name__ == "__main__":
    sys.exit(main(sys.argv))

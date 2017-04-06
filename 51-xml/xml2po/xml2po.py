#
# Copyright (c) 2017 SUSE Linux GmbH
#
# This file is part of xml2po.
#
# xml2po is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# xml2po is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with xml2po. If not, see <http://www.gnu.org/licenses/>.

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

# Keep in sync with brp-trim-polkit-mime-appdata.sh in update-desktop-files
PATH_PATTERNS = {'appstream':
                 [re.compile("/usr/share/metainfo/.+\\.xml"),
                  re.compile("/usr/share/appdata/.+\\.xml")],
                 'polkitaction':
                 [re.compile("/usr/share/polkit-1/actions/.+\\.policy")],
                 "mimeinfo":
                 [re.compile("/usr/share/mime/.+\\.xml")]
                 }


DEFAULT_NAMESPACES = {'mime': 'http://www.freedesktop.org/standards/shared-mime-info'}

# This contains the information on how to generate po files from XML trees.
# For each type it has a list of elements which content is translatable and methods
# to get the needed values/attributes.
TRANSLATABLE_ELEMENTS = {'appstream':
                         [
                            {'path': xml.XPath("/component/name"),
                             'content': xml.XPath("string(./text())"),
                             'lang': xml.XPath("string(./@xml:lang)"),
                             'name': xml.XPath("concat('Name(', string(../id/text()), ')')")},
                            {'path': xml.XPath("/component/summary"),
                             'content': xml.XPath("string(./text())"),
                             'lang': xml.XPath("string(./@xml:lang)"),
                             'name': xml.XPath("concat('Summary(', string(../id/text()), ')')")}
                             # TODO: Description! It's an entire tree...
                         ],
                         'polkitaction':
                         [
                            {'path': xml.XPath("/policyconfig/action/description"),
                             'content': xml.XPath("string(./text())"),
                             'lang': xml.XPath("string(./@xml:lang)"),
                             'name': xml.XPath("concat('Description(', string(../@id), ')')")},
                            {'path': xml.XPath("/policyconfig/action/message"),
                             'content': xml.XPath("string(./text())"),
                             'lang': xml.XPath("string(./@xml:lang)"),
                             'name': xml.XPath("concat('Message(', string(../@id), ')')")}
                         ],
                         'mimeinfo':
                         [
                            {'path': xml.XPath("/mime:mime-type/mime:comment", namespaces=DEFAULT_NAMESPACES),
                             'content': xml.XPath("string(./text())"),
                             'lang': xml.XPath("string(./@xml:lang)"),
                             'name': xml.XPath("concat('Comment(', string(../@type), ')')")}
                         ]
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


def extractXMLLangInfo(file, filepath, type):
    """
    Parses filecontent as XML (of the specified type, see getFileType).
    @returns dict:
    {"Description(org.opensuse.asdf)":
        {'file': "/usr/share/example.xml", 'line': 42,
         'values': {"": "Example", "de": "Beispiel", ...
        },
        ...
    }
    """

    xml_tree = xml.parse(file)

    translations = {}

    for filter in TRANSLATABLE_ELEMENTS[type]:
        for translatable_element in filter['path'](xml_tree):
            name = filter['name'](translatable_element)
            lang = filter['lang'](translatable_element)
            content = filter['content'](translatable_element)

            if name not in translations:
                translations[name] = {'file': filepath, 'line': translatable_element.sourceline, 'values': {}}

            if lang in translations[name]['values']:
                print("Warning: Multiple values for {} in {} ({})", lang, name, filepath)
            else:
                translations[name]['values'][lang] = content

    broken_translations = {k: v for k, v in translations.items() if "" not in v['values']}

    if len(broken_translations) > 0:
        print("Warning: The following translations have no text in the original language: ")
        print(broken_translations)

    return translations


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


def gettextDateTime(when):
    """
    Formats when to be used in PO headers.
    """

    return when.strftime("%Y-%m-%d %H:%M%z")


def generateGettextFiles(lang_info, basename):
    """
    Gets output of extractXMLLangInfo (lang_info),
    returns dict of filenames and (header, content that needs to be appended).
    basename is the basename of the generated PO and POT files
    """

    files = {}
    for ctxt, value in lang_info.items():
        pot_filename = basename + ".pot"
        if pot_filename not in files:
            header = """msgid ""
msgstr ""
"Project-Id-Version: xml2po\\n"
"POT-Creation-Date: {}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"\n\n""".format(gettextDateTime(datetime.now()))
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
"Project-Id-Version: xml2po\\n"
"POT-Creation-Date: {}\\n"
"PO-Revision-Date: {}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"\n\n""".format(gettextDateTime(datetime.now()),
                                                   gettextDateTime(datetime.now()))
                files[po_filename] = {'header': header, 'content': ""}

            files[po_filename]['content'] += translation_header + "msgstr {}\n\n".format(gettextQuote(translation))

    return files


def processTarFile(filepath):
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
                lang_info = extractXMLLangInfo(tar.extractfile(tar_file), tar_file_path, tar_file_type)
            except Exception as e:
                print("Could not extract lang info from {}: {}".format(tar_file_path, e))
                continue

            gettext_output_file = generateGettextFiles(lang_info, tar_file_type)

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

    # Secret option to generate test case output
    if args[1] == "--test":
        print(processTarFile(args[2]))
    else:
        os.chdir(args[2])
        writeGettextFiles(processTarFile(args[1]))


if __name__ == "__main__":
    sys.exit(main(sys.argv))

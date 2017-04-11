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

import sys
import os
import re
from lxml import etree as xml

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


def extractXMLLangInfo(file, filepath, type):
    """
    Parses file as XML (of the specified type, see getFileType).
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

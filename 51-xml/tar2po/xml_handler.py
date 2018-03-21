#
# Copyright (c) 2017 SUSE Linux GmbH
#
# This file is part of tar2po.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
TRANSLATABLE_ELEMENTS = {'appstreamdata':
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
            name = filter['name'](translatable_element).strip()
            lang = filter['lang'](translatable_element).strip()
            content = filter['content'](translatable_element).strip()

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

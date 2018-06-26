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

import os
import re


TRANSLATABLE_ENTRIES = {"Desktop Entry":
                        ["GenericName", "Name", "Comment", "Keywords",
                         "X-KDE-Keywords", "X-GNOME-FullName",
                         "X-Geoclue-Reason", "X-SuSE-YaST-Keywords"],
                        #"Desktop Action *" has special handling in extractDesktopLangInfo
                        }

# This is a special case, the section name can vary
DESKTOPACTION_RE = re.compile("Desktop Action [^\]]+")

COMMENT_RE = re.compile("#.*")
SECTION_RE = re.compile("\[([^\]]+)\]")
ENTRY_RE = re.compile("([^\[=]+)(\[([^=\]]+)\])?\s*=\s*(.*)")


def extractDesktopLangInfo(file, filepath, type):
    """
    Parses file as desktop file (of the specified type, see getFileType).
    @returns dict:
    {"Comment(org.opensuse.asdf)":
        {'file': "/usr/share/applications/org.opensuse.asdf.desktop", 'line': 42,
         'key': "Comment", 'section': "Desktop File",
         'values': {"": "Example", "de": "Beispiel", ...
        },
        ...
    }
    """

    translations = {}
    lineno = 0
    current_section = None
    # Identifier of the desktop file
    basename = os.path.basename(filepath)

    # Step 1: Read all entries + translations into translations
    for line in file:
        lineno += 1
        line = line.decode("utf-8")

        if len(line.strip()) == 0 or COMMENT_RE.match(line):
            continue

        section_match = SECTION_RE.match(line)

        if section_match:
            current_section = section_match.group(1)
            continue

        entry_match = ENTRY_RE.match(line)
        if not entry_match:
            print("Warning: Could not parse desktop file line '{}'!".format(line[:-1]))

        (key, lang, value) = entry_match.group(1, 3, 4)

        assert key is not None

        if current_section == "Desktop Entry":
            ctxt = "{}({})".format(key, basename)
        else:
            ctxt = "{}-{}({})".format(current_section, key, basename)

        if ctxt not in translations:
            translations[ctxt] = {'file': filepath, 'line': lineno,
                                  'section': current_section, 'key': key,
                                  'values': {}}

        if lang is None:
            translations[ctxt]['line'] = lineno
            lang = ''

        if lang in translations[ctxt]['values']:
            print("Warning: Found entry {}{} more than once in {}:{}!".format(key, "" if lang == '' else "(lang {})".format(lang), filepath, line[:-1]))

        translations[ctxt]['values'][lang] = value

    # Step 2: Various warnings + clean up
    for ctxt in list(translations.keys()):
        translation = translations[ctxt]
        # Step 2.1: Warn for invalid translations (no vanilla string)
        if "" not in translation['values']:
            print("Warning: Invalid translation {} at {}:{}".format(ctxt, translation['file'], translation['line']))
            translations.pop(ctxt)
        elif translation['section'] in TRANSLATABLE_ENTRIES and translation['key'] in TRANSLATABLE_ENTRIES[translation['section']]:
            pass  # Keep
        elif DESKTOPACTION_RE.match(translation['section']) and translation['key'] in TRANSLATABLE_ENTRIES['Desktop Entry']:
            # Special handling for "Desktop Action *" sections, treat them as "Desktop Entry"
            pass  # Keep
        # Step 2.2: Warn if translated but not in TRANSLATABLE_ENTRIES
        elif len(translation['values']) > 1:
            print("Warning: Unexpected translation for {} at {}:{}".format(ctxt, translation['file'], translation['line']))
            # Keep to not lose upstream translations
        # Step 2.3:
        else:
            # Not translatable and no translations
            translations.pop(ctxt)

    return translations

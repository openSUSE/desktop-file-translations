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

import ast
from datetime import datetime
import os.path
from operator import is_, eq
import pytest
import sys
from os import path
sys.path.append(path.dirname(path.dirname(path.abspath(__file__))))

import tar2po


def test_invalid(capsys):
    assert tar2po.main([""]) == 1
    assert tar2po.main(["", ""]) == 1
    assert tar2po.main(["", "", "", ""]) == 1
    assert len(capsys.readouterr()[0]) > 0


def test_xml(testcase):
    """Runs one XML testcase"""
    filepart = testcase[:-len("case.tar.xz")]
    output = open(filepart + "out.dict", "r").read() if os.path.isfile(filepart + "out.dict") else ""
    outputdict = ast.literal_eval(output)

    assert outputdict == tar2po.processTarFile(testcase, datetime.fromtimestamp(0))

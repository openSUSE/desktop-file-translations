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

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

import glob
import os
import pytest


def pytest_generate_tests(metafunc):
    """Replace the testcases fixture by all *.case.tar.xz files in tests/cases"""
    if 'testcase' in metafunc.fixturenames:
        location = os.path.dirname(os.path.realpath(__file__))
        testcases = glob.glob(location + "/cases/*.case.tar.xz")
        testcases.sort()  # Sort them alphabetically
        metafunc.parametrize("testcase", testcases)

#
# Copyright (c) 2016 SUSE LLC
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
#
use Mojo::Base -strict;

use Test::More;
use File::Basename 'basename';
use File::Copy 'cp';
use File::Path 'mkpath';
use File::Spec::Functions qw(catdir catfile);
use File::Temp 'tempdir';
use FindBin;
use Mojo::Util qw(files slurp);

my $dir = tempdir CLEANUP => 1;
mkpath catdir($dir, 'desktopfiles');
my @files = map { basename $_} files catdir($FindBin::Bin, 'desktopfiles');
cp catfile($FindBin::Bin, 'desktopfiles', $_), catfile($dir, 'desktopfiles', $_)
  for @files;
mkpath catdir($dir, '50-pot');
@files = map { basename $_} files catdir($FindBin::Bin, '50-pot');
cp catfile($FindBin::Bin, '50-pot', $_), catfile($dir, '50-pot', $_) for @files;
chdir $dir;
my $before = slurp catfile($dir, '50-pot', 'update-desktop-files.pot');
qx{$FindBin::Bin/../update-po-files.sh $dir};
my $after = slurp catfile($dir, '50-pot', 'update-desktop-files.pot');
isnt $before, $after, 'file changed';

done_testing;

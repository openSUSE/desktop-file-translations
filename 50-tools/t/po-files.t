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
use File::Copy 'copy';
use File::Path 'make_path';
use File::Spec::Functions qw(catdir catfile);
use File::Temp 'tempdir';
use FindBin;
use Mojo::Util qw(files slurp);

# Prepare the download sirectory
my $dir = tempdir CLEANUP => 1;
make_path catdir($dir, 'desktopfiles');
my @files = map { basename $_} files catdir($FindBin::Bin, 'desktopfiles');
copy catfile($FindBin::Bin, 'desktopfiles', $_),
  catfile($dir, 'desktopfiles', $_)
  for @files;
make_path catdir($dir, '50-pot');
@files = map { basename $_} files catdir($FindBin::Bin, '50-pot');
copy catfile($FindBin::Bin, '50-pot', $_), catfile($dir, '50-pot', $_)
  for @files;
make_path catdir($dir, 'de');
@files = map { basename $_} files catdir($FindBin::Bin, 'de');
copy catfile($FindBin::Bin, 'de', $_), catfile($dir, 'de', $_) for @files;

# Process files from download directory
chdir $dir;
my $all_before = slurp catfile($dir, '50-pot', 'update-desktop-files.pot');
my $apps_before
  = slurp catfile($dir, '50-pot', 'update-desktop-files-apps.pot');
my $all_de_before = slurp catfile($dir, 'de', 'update-desktop-files.po');
qx{$FindBin::Bin/../update-po-files.sh $dir};
my $all_after = slurp catfile($dir, '50-pot', 'update-desktop-files.pot');
isnt $all_before, $all_after, 'file changed';
my $apps_after = slurp catfile($dir, '50-pot', 'update-desktop-files-apps.pot');
isnt $apps_before, $apps_after, 'file changed';
my $all_de_after = slurp catfile($dir, 'de', 'update-desktop-files.po');
isnt $all_de_before, $all_de_after, 'file changed';

# Results
like $all_de_after, qr/msgctxt "GenericName\(firefox\.desktop\)"/,
  'msgctxt has been added';
like $all_de_after, qr/msgid "Web Browser"/, 'msgid has been added';
like $all_de_after, qr/msgctxt "Name\(x-blend\.desktop\)"/,
  'msgctxt has been added';
like $all_de_after, qr/msgid "blender"/, 'msgid has been added';

done_testing;

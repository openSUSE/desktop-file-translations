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

# Prepare the download directory
my $dir = tempdir CLEANUP => 1;
for my $subdir (qw(desktopfiles 50-pot de es)) {
  make_path catdir($dir, $subdir);
  my @files = map { basename $_} files catdir($FindBin::Bin, $subdir);
  copy catfile($FindBin::Bin, $subdir, $_), catfile($dir, $subdir, $_)
    for @files;
}

sub text_like {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  like shift, qr/\Q@{[shift()]}\E/, shift;
}

chdir $dir;
qx{$FindBin::Bin/../build-entries-po.sh};
ok -e catfile($dir, 'po', 'de', 'entries.po'), '"de/entires.po" exists';
ok -e catfile($dir, 'po', 'es', 'entries.po'), '"es/entries.po" exists';
my $de = slurp catfile($dir, 'po', 'de', 'entries.po');
my $es = slurp catfile($dir, 'po', 'es', 'entries.po');

# "po/de/entries.po"
text_like $de, '"Language: de\n"', 'contains snippet';
text_like $de, <<'EOF', 'contains snippet';
msgid "Comment(xcowhelp.desktop):  A help for cowsay"
msgstr ""
EOF
text_like $de, <<'EOF', 'contains snippet';
msgid "Comment(libreoffice-extension.desktop): %PRODUCTNAME Extension"
msgstr "%PRODUCTNAME Erweiterung"
EOF
text_like $de, <<'EOF', 'contains snippet';
msgid "Comment(icewm.desktop): A Windows 95-OS/2-Motif-like window manager"
msgstr "Fenstermanager im Stil von Windows 95, OS/2 und Motif"
EOF

# "po/es/entries.po"
text_like $es, '"Language: es\n"', 'contains snippet';
text_like $es, <<'EOF', 'contains snippet';
msgid "Comment(icewm.desktop): A Windows 95-OS/2-Motif-like window manager"
msgstr "Un administrador de ventanas similar a Win95-OS/2-Motif"
EOF

done_testing;

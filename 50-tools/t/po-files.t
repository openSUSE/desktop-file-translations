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

# Test helpers
sub slurp_dir { slurp catfile($dir, @_) }
sub text_like   { like shift,   qr/\Q@{[shift()]}\E/, shift }
sub text_unlike { unlike shift, qr/\Q@{[shift()]}\E/, shift }

# Process files from download directory
chdir $dir;
my $before = {
  all     => slurp_dir('50-pot', 'update-desktop-files.pot'),
  apps    => slurp_dir('50-pot', 'update-desktop-files-apps.pot'),
  all_de  => slurp_dir('de',     'update-desktop-files.po'),
  apps_de => slurp_dir('de',     'update-desktop-files-apps.po'),
  mime_de => slurp_dir('de',     'update-desktop-files-mimelnk.po'),
  all_es  => slurp_dir('es',     'update-desktop-files.po')
};
qx{$FindBin::Bin/../update-po-files.sh $dir};
my $after = {
  all     => slurp_dir('50-pot', 'update-desktop-files.pot'),
  apps    => slurp_dir('50-pot', 'update-desktop-files-apps.pot'),
  all_de  => slurp_dir('de',     'update-desktop-files.po'),
  apps_de => slurp_dir('de',     'update-desktop-files-apps.po'),
  mime_de => slurp_dir('de',     'update-desktop-files-mimelnk.po'),
  all_es  => slurp_dir('es',     'update-desktop-files.po')
};
isnt $before->{all}, $after->{all}, '"update-desktop-files.pot" file changed';
isnt $before->{apps}, $after->{apps},
  '"update-desktop-files-apps.pot" file changed';
isnt $before->{all_de}, $after->{all_de},
  '"de/update-desktop-files.po" file changed';
isnt $before->{apps_de}, $after->{apps_de},
  '"de/update-desktop-files-apps.po" file changed';
isnt $before->{mime_de}, $after->{mime_de},
  '"de/update-desktop-files-mimelnk.po" file changed';

# "update-desktop-files.pot"
text_like $before->{all}, <<'EOF', 'contains snippet';
msgctxt "Comment(icewm.desktop)"
msgid "A Windows 95-OS/2-Motif-like window manager"
msgstr ""
EOF
text_unlike $after->{all}, <<'EOF', 'no longer contains snippet';
msgctxt "Comment(icewm.desktop)"
msgid "A Windows 95-OS/2-Motif-like window manager"
msgstr ""
EOF
text_like $after->{all}, <<'EOF', 'contains snippet';
msgctxt "Comment(libreoffice-extension.desktop)"
msgid "%PRODUCTNAME Extension"
msgstr ""
EOF

# "update-desktop-files-apps.pot"
text_like $before->{apps}, <<'EOF', 'contains snippet';
msgctxt "Comment(xcowhelp.desktop)"
msgid " A help for cowsay"
msgstr ""
EOF
text_unlike $after->{apps}, <<'EOF', 'no longer contains snippet';
msgctxt "Comment(xcowhelp.desktop)"
msgid " A help for cowsay"
msgstr ""
EOF
text_like $after->{apps}, <<'EOF', 'contains snippet';
msgctxt "Name(x-blend.desktop)"
msgid "blender"
msgstr ""
EOF
text_like $after->{apps}, <<'EOF', 'contains snippet';
msgctxt "GenericName(firefox.desktop)"
msgid "Web Browser"
msgstr ""
EOF
text_like $after->{apps}, <<'EOF', 'contains snippet';
msgctxt "GenericName(impress.desktop)"
msgid "Presentation"
msgstr ""
EOF

# "de/update-desktop-files.po"
text_like $before->{all_de}, <<'EOF', 'contains snippet';
msgctxt "Comment(icewm.desktop)"
msgid "A Windows 95-OS/2-Motif-like window manager"
msgstr "Fenstermanager im Stil von Windows 95, OS/2 und Motif"
EOF
text_unlike $after->{all_de}, <<'EOF', 'no longer contains snippet';
msgctxt "Comment(icewm.desktop)"
msgid "A Windows 95-OS/2-Motif-like window manager"
msgstr "Fenstermanager im Stil von Windows 95, OS/2 und Motif"
EOF
text_like $after->{all_de}, <<'EOF', 'contains snippet';
msgctxt "Comment(libreoffice-extension.desktop)"
msgid "%PRODUCTNAME Extension"
msgstr "%PRODUCTNAME Erweiterung"
EOF

# "de/update-desktop-files-apps.po"
text_like $before->{apps_de}, <<'EOF', 'contains snippet';
msgctxt "Comment(xcowhelp.desktop)"
msgid " A help for cowsay"
msgstr ""
EOF
text_unlike $after->{apps_de}, <<'EOF', 'no longer contains snippet';
msgctxt "Comment(xcowhelp.desktop)"
msgid " A help for cowsay"
msgstr ""
EOF
text_like $after->{apps_de}, <<'EOF', 'contains snippet';
msgctxt "GenericName(xsltfilter.desktop)"
msgid "XSLT based filters"
msgstr "XSLT basierte Filter"
EOF

# "de/update-desktop-files-mimelnk.po"
text_like $before->{mime_de}, <<'EOF', 'contains snippet';
msgctxt "Comment(libreoffice-extension.desktop)"
msgid "%PRODUCTNAME Extension"
msgstr "%PRODUCTNAME Erweiterung"
EOF
text_like $after->{mime_de}, <<'EOF', 'contains snippet';
msgctxt "Comment(libreoffice-extension.desktop)"
msgid "%PRODUCTNAME Extension"
msgstr "%PRODUCTNAME Erweiterung"
EOF
text_like $after->{mime_de}, <<'EOF', 'contains snippet';
msgctxt "Comment(libreoffice-ms-excel-sheet-12.desktop)"
msgid "Microsoft Excel Worksheet"
msgstr ""
EOF

# "es/update-desktop-files.po"
text_like $before->{all_es}, <<'EOF', 'contains snippet';
msgctxt "Comment(icewm.desktop)"
msgid "A Windows 95-OS/2-Motif-like window manager"
msgstr "Un administrador de ventanas similar a Win95-OS/2-Motif"
EOF
text_unlike $after->{all_es}, <<'EOF', 'no longer contains snippet';
msgctxt "Comment(icewm.desktop)"
msgid "A Windows 95-OS/2-Motif-like window manager"
msgstr "Un administrador de ventanas similar a Win95-OS/2-Motif"
EOF
text_like $after->{all_es}, <<'EOF', 'contains snippet';
msgctxt "Comment(libreoffice-extension.desktop)"
msgid "%PRODUCTNAME Extension"
msgstr ""
EOF

done_testing;

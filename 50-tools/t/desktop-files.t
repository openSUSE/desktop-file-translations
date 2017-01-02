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

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Mojo::Util 'slurp';
use Mojolicious::Lite;
use SUSE::DesktopFileDownloader;

app->log->level('fatal');
push @{app->static->paths}, catfile($FindBin::Bin, 'desktopfiles');

my $entries = <<EOF;
<directory>
  <entry name="blender" />
  <entry name="MozillaFirefox" />
  <entry name="SomeMissingFile" />
<directory>
EOF
get '/' => {text => $entries};

my $downloader = SUSE::DesktopFileDownloader->new(urls => ['/'], silent => 1);
$downloader->ua->server->app(app);

# Download a few files into a target directory
my $dir = tempdir CLEANUP => 1;
$downloader->download($dir);
my $blender = catfile $dir, 'desktopfiles', '1-blender.desktopfiles';
ok -f $blender, 'file exists';
like slurp($blender), qr/Modelador 3D/, 'right content';
my $firefox = catfile $dir, 'desktopfiles', '1-MozillaFirefox.desktopfiles';
ok -f $firefox, 'file exists';
like slurp($firefox), qr/Web Browser/, 'right content';

done_testing;

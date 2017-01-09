#!/usr/bin/env perl
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
use lib "$FindBin::Bin/lib";

use Mojo::Util 'getopt';
use Mojolicious::Command;
use SUSE::DesktopFileDownloader;

# Add or remove projects here
my @urls = (
  'https://api.opensuse.org/public/build/openSUSE:Leap:42.2/standard/x86_64',
  'https://api.opensuse.org/public/build/openSUSE:Leap:42.2:NonFree/standard/x86_64'
);

my $downloader = SUSE::DesktopFileDownloader->new(urls => \@urls);
getopt \@ARGV,
  'j=i'    => sub { $downloader->concurrency($_[1]) },
  'h|help' => \my $help;

die Mojolicious::Command->new->extract_usage if $help || !(my $target = shift);

$downloader->download($target);

=encoding utf8

=head1 NAME

download-desktop-files.pl

=head1 SYNOPSIS

  Usage: download-desktop-files.pl [TARGET]

    download-desktop-files.pl /tmp/download-directory
    download-desktop-files.pl -j 4 /tmp/download-directory

  Options:
    -j <concurrency>   Number of concurrent connections to use for downloading,
                       defaults to 2
    -h, --help         Show this message

=cut

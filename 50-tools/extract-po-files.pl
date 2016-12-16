#!/usr/bin/perl
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

#
# This script is a dependency of "desktop-files-update.sh", and should not be
# used directly
#

use POSIX;
use File::Basename;

my $lang = $ARGV[0] || undef;

sub print_po_line($$) {
  my ($ltag, $lstr) = @_;
  my $escaped_str = $lstr;
  $escaped_str =~ s,\\,\\\\,g;
  $escaped_str =~ s,",\\",g;
  print STDOUT "$ltag \"$escaped_str\"\n";
}

opendir(DIR, "desktopfiles");
@files = readdir(DIR);
@files = sort @files;
close in;

my $version = POSIX::strftime("%Y%m%d", localtime(time()));
my $date = POSIX::strftime("%Y-%m-%d %H:%M+0000", localtime(time()));
print STDOUT "msgid \"\"\n";
print STDOUT "msgstr \"\"\n";
print STDOUT "\"Project-Id-Version: desktop-translations $version\\n\"\n";
print STDOUT "\"MIME-Version: 1.0\\n\"\n";
print STDOUT "\"Content-Type: text/plain; charset=UTF-8\\n\"\n";
print STDOUT "\"Content-Transfer-Encoding: 8bit\\n\"\n";
print STDOUT "\"POT-Creation-Date: $date\\n\"\n";
print STDOUT "\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"\n";
print STDOUT "\"Last-Translator: FULL NAME <EMAIL\@ADDRESS>\\n\"\n";
print STDOUT "\"Language-Team: LANGUAGE <LL\@li.org>\\n\"\n";
print STDOUT "\n";

my $desktopfile  = "";
my $DESKTOP_FILE = "";
my $prefix;
my %tags = ();

sub getprefix($) {
  my ($dir) = @_;

#  print STDERR "$dir\n";
  if ($dir =~ m,^/opt/kde3,) {
    return '9';
  }
  if ($dir =~ m,^/usr/share/applications/YaST2,) {
    return '2';
  }
  if ($dir =~ m,^/usr/share/applications,) {
    return '1';
  }
  return '4';
}

my %seen_lines = ();

foreach my $file (@files) {
  open(FILE, "desktopfiles/$file");
  while (<FILE>) {
    my $tag = "";
    my $str = "";

    if (/^<<(.*)>>$/) {
      while (($tag, $otag) = each(%tags)) {
        print_po_line("msgctxt", "$tag($DESKTOP_FILE)");
        my $otag = print_po_line("msgid", "PREFIX$prefix-$otag");
        print_po_line("msgstr", "NADA");
        print STDOUT "\n";
      }

      $desktopfile = $1;
      $desktopfile =~ s,/*var/tmp/.*-build,,;
      $desktopfile =~ s,.*/BUILDROOT/[^/]*,,;
      $desktopfile =~ s,//*,/,g;
      $prefix       = getprefix(dirname($desktopfile));
      $DESKTOP_FILE = $desktopfile;
      $DESKTOP_FILE =~ s,.*/,,;

      # not used $DESKTOP_FILE = "$prefix-$DESKTOP_FILE" if ($prefix);

      %tags = ();
      next;
    }

    if (/^(Name)=(..*)$/ || /^(GenericName)=(..*)$/ || /^(Comment)=(..*)$/) {
      $tag = $1;
      $str = $2;

      if (!$lang) {
        print STDOUT "#: $desktopfile\n";
        print_po_line("msgctxt", "$tag($DESKTOP_FILE)");
        print_po_line("msgid",   "PREFIX$prefix-$str");
        my $key = "$tag($DESKTOP_FILE)=$str";
        if (defined $seen_lines{$key} && $seen_lines{$key} ne $desktopfile) {

          #print STDERR "seen dup $seen_lines{$key} vs $desktopfile\n";
        }
        $seen_lines{$key} = $desktopfile;
        print_po_line("msgstr", "");
        print STDOUT "\n";
      }
      else {
        $tags{$tag} = $str;
      }
    }

    if (
      length($lang)
      && ( /^(Name)\[$lang\]=(..*)$/
        || /^(GenericName)\[$lang\]=(..*)$/
        || /^(Comment)\[$lang\]=(..*)$/)
      )
    {
      print STDOUT "#: $desktopfile\n";
      my $otag = $tags{$1};
      if (length($otag)) {
        print_po_line("msgctxt", "$1($DESKTOP_FILE)");
        print_po_line("msgid",   "PREFIX$prefix-$otag");
        print_po_line("msgstr",  "$2");
        print STDOUT "\n";
        delete $tags{$1};
      }
      next;
    }
  }
}

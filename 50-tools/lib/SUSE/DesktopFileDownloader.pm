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
package SUSE::DesktopFileDownloader;
use Mojo::Base -base;

use Carp 'croak';
use File::Path 'make_path';
use File::Spec::Functions qw(catdir catfile);
use Mojo::IOLoop;
use Mojo::UserAgent;
use Term::ProgressBar;

has concurrency => 2;
has silent      => 0;
has ua          => sub { Mojo::UserAgent->new };
has urls        => sub { [] };

sub download {
  my ($self, $target) = @_;

  my $path = catdir $target, 'desktopfiles';
  make_path $path or croak qq{Can't make directory "$path": $!} unless -d $path;

  my $i = 1;
  $self->_download($path, $_, $i++) for @{$self->urls};
}

sub _check {
  my $tx = shift;
  if (my $res = $tx->success) { return $res }
  my $err = $tx->error;
  return undef if $err->{code};
  die "Connection error: $err->{message}";
}

sub _download {
  my ($self, $path, $url, $prefix) = @_;

  my $tx = $self->ua->get($url);
  return unless my $res = _check($tx);
  my $names = $res->dom->find('entry')->map(sub { $_->{name} })->to_array;

  say "$url:" unless $self->silent;
  my $progress = Term::ProgressBar->new(
    {count => scalar @$names, term_width => 80, silent => $self->silent});

  my $delay = Mojo::IOLoop->delay;
  my $fetch;
  $fetch = sub {
    return unless my $name = shift @$names;
    my $end = $delay->begin;
    $self->ua->get(
      "$url/$name/$name.desktopfiles" => sub {
        my ($ua, $tx) = @_;
        my $res = _check($tx);
        my $target = catfile $path, "$prefix-$name.desktopfiles";
        $res->content->asset->move_to($target) if $res;
        $progress->update;
        $end->();
        $fetch->();
      }
    );
  };
  $fetch->() for 1 .. $self->concurrency;
  $delay->wait;
}

1;

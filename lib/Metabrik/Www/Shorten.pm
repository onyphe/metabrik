#
# $Id$
#
# www::shorten Brik
#
package Metabrik::Www::Shorten;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable shortener url uri) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         ssl_verify => [ qw(0|1) ],
      },
      attributes_default => {
         ssl_verify => 0,
      },
      commands => {
         'shorten' => [ qw(uri) ],
         'unshorten' => [ qw(uri) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::String::Uri' => [ ],
      },
   };
}

sub shorten {
   my $self = shift;
   my ($uri) = @_;

   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('shorten'));
   }

   my $service = 'http://url.pm';

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->post({ _url => $uri }, $service) or return;

   my $shorten;
   my $content = $cw->content or return;
   if (length($content)) {
      ($shorten) = $content =~ m{(http://url\.pm/[^"]+)};
   }

   return $shorten;
}

sub unshorten {
   my $self = shift;
   my ($uri) = @_;

   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('unshorten'));
   }

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $trace = $cw->trace_redirect($uri) or return;

   my $unshorten;
   if (@$trace > 0 && exists($trace->[-1]->{uri})) {
      $unshorten = $trace->[-1]->{uri};
   }

   return $unshorten;
}

1;

__END__

=head1 NAME

Metabrik::Www::Shorten - www::shorten Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

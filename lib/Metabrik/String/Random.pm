#
# $Id$
#
# string::random Brik
#
package Metabrik::String::Random;
use strict;
use warnings;

use base qw(Metabrik::String::Password);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable string random) ],
      attributes_default => {
         datadir => [ qw(datadir) ],
         charset => [ 'A'..'K', 'M'..'Z', 'a'..'k', 'm'..'z', 2..9, '_', '-' ],
         length => 20,
         count => 1,
      },
      commands => {
         filename => [ qw(datadir|OPTIONAL) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->global->datadir.'/string-random';

   return {
      attributes_default => {
         datadir => $datadir,
      },
   };
}

sub brik_init {
   my $self = shift;

   my $dir = $self->datadir;
   if (! -d $dir) {
      mkdir($dir)
         or return $self->log->error("brik_init: mkdir failed for dir [$dir]");
   }

   return $self->SUPER::brik_init(@_);
}

sub filename {
   my $self = shift;
   my ($datadir) = @_;

   $datadir ||= $self->datadir;

   my $random = $self->generate;

   return "$datadir/".$random->[0];
}

1;

__END__

=head1 NAME

Metabrik::String::Random - string::random Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

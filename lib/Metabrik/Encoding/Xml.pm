#
# $Id$
#
# encoding::xml Brik
#
package Metabrik::Encoding::Xml;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable encode decode xml) ],
      commands => {
         encode => [ qw($data_hash) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'XML::Simple' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encode'));
   }

   if (ref($data) ne 'HASH') {
      return $self->log->error("encode: you need to give data as HASHREF");
   }

   my $xs = XML::Simple->new;

   return $xs->XMLout($data);
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('decode'));
   }

   my $xs = XML::Simple->new;

   return $xs->XMLin($data);
}

1;

__END__

=head1 NAME

Metabrik::Encoding::Xml - encoding::xml Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

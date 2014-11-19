#
# $Id: Rot13.pm 179 2014-10-02 18:04:01Z gomor $
#
# encoding::rot13 Brik
#
package Metabrik::Encoding::Rot13;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable encode decode rot13) ],
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encode'));
   }

   (my $encoded = $data) =~ tr/n-za-m/a-z/;

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('decode'));
   }

   return $self->encode($data);
}

1;

__END__

=head1 NAME

Metabrik::Encoding::Rot13 - encoding::rot13 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

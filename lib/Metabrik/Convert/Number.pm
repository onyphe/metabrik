#
# $Id$
#
# convert::number Brik
#
package Metabrik::Convert::Number;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         to_hex => [ qw(int_number) ],
         to_int => [ qw(hex_number) ],
      },
   };
}

sub to_hex {
   my $self = shift;
   my ($int) = @_;

   if (! defined($int)) {
      return $self->log->error($self->brik_help_run('hex'));
   }

   if ($int !~ /^[0-9]+/) {
      return $self->log->error("hex: invalid format for int [$int]");
   }

   return sprintf("0x%x", $int);
}

sub to_int {
   my $self = shift;
   my ($hex) = @_;

   if (! defined($hex)) {
      return $self->log->error($self->brik_help_run('int'));
   }

   if ($hex !~ /^[0-9a-f]+$/i && $hex !~ /^0x[0-9a-f]+$/i) {
      return $self->log->error("int: invalid format for hex [$hex]");
   }

   return sprintf("%d", hex($hex));
}

1;

__END__

=head1 NAME

Metabrik::Convert::Number - convert::number Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

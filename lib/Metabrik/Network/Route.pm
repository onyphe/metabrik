#
# $Id$
#
# system::route Brik
#
package Metabrik::System::Route;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable route) ],
      attributes => {
         _dnet => [ qw(Net::Libdnet::Route) ],
      },
      commands => {
         show => [ ],
      },
      require_modules => {
         'Net::Libdnet::Route' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $dnet = Net::Libdnet::Route->new
      or return $self->log->error("can't create Net::Libdnet::Route object");

   $self->_dnet($dnet);

   return $self->SUPER::brik_init;
}

sub _display {
   my ($entry, $data) = @_;

   my $buf = sprintf("%-30s %-30s", $entry->{route_dst}, $entry->{route_gw});
   print "$buf\n";

   return $buf;
}

sub show {
   my $self = shift;

   printf("%-30s %-30s\n", 'Destination', 'Gateway');
   my $data = '';
   $self->_dnet->loop(\&_display, \$data);

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::System::Route - system::route Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id$
#
# network::netbios Brik
#
package Metabrik::Network::Netbios;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable netbios) ],
      commands => {
         probe => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Net::NBName' => [ ],
      },
   };
}

sub probe {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->error($self->brik_help_run('probe'));
   }

   my $nb = Net::NBName->new;
   if (! $nb) {
      return $self->log->error("can't new() Net::NBName: $!");
   }

   my $ns = $nb->node_status($ip);
   if ($ns) {
      print $ns->as_string;
      return $nb;
   }

   print "no response\n";

   return $nb;
}

1;

__END__

=head1 NAME

Metabrik::Network::Netbios - network::netbios Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

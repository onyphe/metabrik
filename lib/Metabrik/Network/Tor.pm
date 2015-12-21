#
# $Id$
#
# network::tor Brik
#
package Metabrik::Network::Tor;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable exitnodes) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],
      },
      # alternatives:
      # https://www.dan.me.uk/torlist/
      # https://check.torproject.org/exit-addresses
      #
      # https://www.dan.me.uk/torcheck?ip=2.100.184.78
      # https://globe.torproject.org/
      # https://atlas.torproject.org/
      attributes_default => {
         uri => 'http://torstatus.blutmagie.de/ip_list_exit.php/Tor_ip_list_EXIT.csv',
      },
      commands => {
         exit_nodes_list => [ ],
      },
   };
}

sub exit_nodes_list {
   my $self = shift;

   my $get = $self->get or return;

   my $ip_list = $get->{content};

   my @ip_list = split(/\n/, $ip_list);

   return \@ip_list;
}

1;

__END__

=head1 NAME

Metabrik::Network::Tor - network::tor Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

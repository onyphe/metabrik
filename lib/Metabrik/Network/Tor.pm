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
      tags => [ qw(unstable tor exitnodes) ],
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

   my $get = $self->get or return $self->log->error('exit_nodes_list: get failed');

   my $ip_list = $get->{body};

   my @ip_list = split(/\n/, $ip_list);
   my %ip_list = ();
   for my $ip (@ip_list) {
      $ip_list{$ip} = 1;
   }

   return {
      as_list => \@ip_list,
      as_hash => \%ip_list,
   };
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

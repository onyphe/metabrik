#
# $Id$
#
# network::arp Brik
#
package Metabrik::Network::Arp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable arp cache poison) ],
      attributes => {
         _dnet => [ qw(Net::Libdnet::Arp) ],
      },
      commands => {
         cache => [ ],
         half_poison => [ ],
         full_poison => [ ],
      },
      require_modules => {
         'Net::Libdnet::Arp' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $dnet = Net::Libdnet::Arp->new;
   if (! defined($dnet)) {
      return $self->log->error("unable to create Net::Libdnet::Arp object");
   }

   $self->_dnet($dnet);

   return $self->SUPER::brik_init;
}

sub _loop {
   my ($entry, $data) = @_;

   $data->{ip}->{$entry->{arp_pa}} = $entry->{arp_ha};
   $data->{mac}->{$entry->{arp_ha}} = $entry->{arp_pa};

   return $data;
}

sub cache {
   my $self = shift;

   my %data = ();
   $self->_dnet->loop(\&_loop, \%data);

   return \%data;
}

sub half_poison {
   my $self = shift;

   $self->log->info("TODO");

   return 1;
}

sub full_poison {
   my $self = shift;

   $self->log->info("TODO");

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Arp - network::arp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

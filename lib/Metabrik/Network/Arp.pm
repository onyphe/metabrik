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
      tags => [ qw(unstable arp cache poison eui64) ],
      attributes => {
         _dnet => [ qw(Net::Libdnet::Arp) ],
      },
      commands => {
         cache => [ ],
         half_poison => [ ],
         full_poison => [ ],
         mac2eui64 => [ qw(mac_address) ],
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
      return $self->log->error("brik_init: unable to create Net::Libdnet::Arp object");
   }

   $self->_dnet($dnet);

   return $self->SUPER::brik_init(@_);
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

# Taken from Net::SinFP3
sub mac2eui64 {
   my $self = shift;
   my ($mac) = @_;

   if (! defined($mac)) {
      return $self->log->error($self->brik_help_run('mac2eui64'));
   }

   if ($mac !~ /^[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}:[0-9a-z]{2}$/i) {
      return $self->log->error("mac2eui64: invalid MAC address [$mac]");
   }

   my @b  = split(':', $mac);
   my $b0 = hex($b[0]) ^ 2;

   return sprintf("fe80::%x%x:%xff:fe%x:%x%x", $b0, hex($b[1]), hex($b[2]),
      hex($b[3]), hex($b[4]), hex($b[5]));
}

1;

__END__

=head1 NAME

Metabrik::Network::Arp - network::arp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

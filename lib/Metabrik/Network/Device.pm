#
# $Id$
#
# network::device Brik
#
package Metabrik::Network::Device;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network device interface) ],
      attributes => {
         'enable_warnings' => [ qw(0|1) ],
      },
      attributes_default => {
         'enable_warnings' => 0,
      },
      commands => {
         default => [ ],
         get => [ qw(device) ],
         list => [ ],
         show => [ ],
         internet_address => [ ],
      },
      require_modules => {
         'Net::Libdnet::Intf' => [ ],
         'Net::Pcap' => [ ],
         'Net::Routing' => [ ],
         'Metabrik::Client::Www' => [ ],
      },
   };
}

sub _to_dot_quad {
   my $self = shift;
   my ($i) = @_;

   return ($i >> 24 & 255).'.'.($i >> 16 & 255).'.'.($i >> 8 & 255).'.'.($i & 255);
}

sub list {
   my $self = shift;

   my $dev = {};
   my $err = '';
   my @devs = Net::Pcap::findalldevs($dev, \$err);
   if (length($err) || @devs == 0) {
      return $self->log->error("list: findalldevs failed with error [$err]");
   }

   return \@devs;
}

sub get {
   my $self = shift;
   my ($device) = @_;

   if (! defined($device)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $intf = Net::Libdnet::Intf->new;
   if (! defined($intf)) {
      $self->enable_warnings
         && $self->log->warning("list: Net::Libdnet::Intf new failed for device [$device]");
      next;
   }

   my $get = $intf->get($device);
   if (! defined($get)) {
      $self->enable_warnings
         && $self->log->warning("list: Net::Libdnet::Intf get failed for device [$device]");
      next;
   }

   my $network;
   my $mask;
   my $err = '';
   if (Net::Pcap::lookupnet($device, \$network, \$mask, \$err) < 0) {
      $self->enable_warnings
         && $self->log->warning("list: lookupnet failed for device [$device] with error [$err]");
   }

   my $dot_network = $self->_to_dot_quad($network);
   #my $dot_mask = $self->_to_dot_quad($mask);

   my $dev = {
      interface => $device,
   };

   # Check Net::Libdnet::Entry::Intf for more
   my $ip;
   my $cidr;
   my $mac;
   if ($ip = $get->ip) {
      $dev->{ipv4} = $ip;
   }
   if ($cidr = $get->cidr) {
      $dev->{cidr} = $cidr;
   }
   if ($mac = $get->linkAddr) {
      $dev->{mac} = $mac;
   }
   my @aliases = $get->aliasAddrs;
   if (@aliases > 0) {
      # IPv6 are within aliases. First one if the main IPv6 address.
      if (defined($aliases[0])) {
         $dev->{ipv6} = $aliases[0];
      }
   }

   if (defined($ip) && defined($cidr)) {
      $dev->{subnet} = "$dot_network/$cidr";
   }

   return $dev;
}

sub default {
   my $self = shift;
   my ($destination) = @_;

   $destination ||= '8.8.8.8'; # Default route to Internet Google DNS nameserver

   my $family = Net::Routing::NR_FAMILY_INET4();

   my $nr = Net::Routing->new(
      target => $destination,
      family => $family,
   );
   if (! defined($nr)) {
      return $self->log->error("default: new failed: $Net::Routing::Error");
   }

   my $list = $nr->get
      or return $self->log->error("default: get failed: $Net::Routing::Error");
   # Only one possibility, that's great
   if (@$list == 1) {
      return $list->[0]->{interface};
   }
   # Or we return every possible interface
   else {
      my %interfaces = ();
      for my $i (@$list) {
         $interfaces{$i->{interface}}++;
      }
      return [ keys %interfaces ];
   }

   # Error
   return;
}

sub show {
   my $self = shift;

   my $devices = $self->list or return $self->log->error("show: list failed");

   for my $this (keys %$devices) {
      my $device = $self->get($this);
      if (! defined($device)) {
         $self->enable_warnings
            && $self->log->warning("show: get failed for device [$this]");
         next;
      }

      # XXX: to complete
      printf("interface: %s  ipv4: %s\n", $device->{interface}, $device->{ipv4});
   }

   return 1;
}

sub internet_address {
   my $self = shift;

   my $client_www = Metabrik::Client::Www->new_from_brik($self) or return;

   #my $url = 'http://ip.nu';
   my $url = 'http://www.whatsmyip.net/';
   my $get = $client_www->get($url)
      or return $self->log->error("internet_address: get failed");

   my $html = $get->{body};

   my ($ip) = $html =~ /(\d+\.\d+\.\d+\.\d+)/;

   return $ip || undef;
}

1;

__END__

=head1 NAME

Metabrik::Network::Device - network::device Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

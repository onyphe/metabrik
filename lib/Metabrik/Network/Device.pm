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
      },
      require_modules => {
         'Net::Libdnet::Intf' => [ ],
         'Net::Pcap' => [ ],
         'Net::Frame::Device' => [ ],
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

   my $devices = {};

   my $dev = {};
   my $err = '';
   Net::Pcap::findalldevs($dev, \$err);
   if (length($err)) {
      return $self->log->error("list: findalldevs failed with error [$err]");
   }

   for my $this (keys %$dev) {
      $devices->{$this}->{device} = $this;

      my $network;
      my $mask;
      $err = '';
      if (Net::Pcap::lookupnet($this, \$network, \$mask, \$err) < 0) {
         $self->enable_warnings && $self->log->warning("list: lookupnet failed for device [$this] with error [$err]");
         $err = '';
         next;
      }

      my $dot_network = $self->_to_dot_quad($network);
      my $dot_mask = $self->_to_dot_quad($mask);

      $devices->{$this}->{network} = $dot_network;
      $devices->{$this}->{mask} = $dot_mask;

      my $intf = Net::Libdnet::Intf->new;
      if (! defined($intf)) {
         $self->enable_warnings && $self->log->warning("list: Net::Libdnet::Intf new failed for device [$this]");
         next;
      }
      my $get = $intf->get($this);
      if (! defined($get)) {
         $self->enable_warnings && $self->log->warning("list: Net::Libdnet::Intf get failed for device [$this]");
         next;
      }

      # Check Net::Libdnet::Entry::Intf for more
      #$devices->{$this}->{_get} = $get;
      my $ip;
      my $cidr;
      my $mac;
      if ($ip = $get->ip) {
         $devices->{$this}->{ipv4} = $ip;
      }
      if ($cidr = $get->cidr) {
         $devices->{$this}->{cidr} = $cidr;
      }
      if ($mac = $get->linkAddr) {
         $devices->{$this}->{mac} = $mac;
      }
      my @aliases = $get->aliasAddrs;
      if (@aliases > 0) {
         # IPv6 are within aliases. First one if the main IPv6 address.
         if (defined($aliases[0])) {
            $devices->{$this}->{ipv6} = $aliases[0];
         }
      }

      if (defined($ip) && defined($cidr)) {
         $devices->{$this}->{subnet} = "$dot_network/$cidr";
      }
   }

   return $devices;
}

sub get {
   my $self = shift;
   my ($device) = @_;

   if (! defined($device)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $list = $self->list or return $self->log->error("get: list failed");

   if (! exists($list->{$device})) {
      return $self->log->error($self->brik_help_run('get'));
   }

   return $list->{$device};
}

sub default {
   my $self = shift;
   my ($destination) = @_;

   $destination ||= '8.8.8.8'; # Default route to Internet Google DNS nameserver

   my $get;
   if (defined($destination)) {
      my $intf = Net::Libdnet::Intf->new;
      if (! defined($intf)) {
         return $self->log->error("default: Net::Libdnet::Intf new failed");
      }

      $get = $intf->getSrcIntfFromDst($destination);
   }
   else {
      my $intf = Net::Libdnet::Intf->new;
      if (! defined($intf)) {
         return $self->log->error("default: Net::Libdnet::Intf new failed");
      }

      $get = $intf->get;
   }

   if (! defined($get)) {
      return $self->log->error("default: get failed");
   }

   my $list = $self->list or return $self->log->error("default: list failed");

   return $list->{$get};
}

sub show {
   my $self = shift;

   my $devices = $self->list or return $self->log->error("show: list failed");

   for my $this (keys %$devices) {
      my $device = Net::Libdnet::Intf->new;
      if (! defined($device)) {
         $self->enable_warnings && $self->log->warning("show: Net::Libdnet::Intf new failed for device [$this]");
         next;
      }

      my $get = $device->get($this);
      if (! defined($get)) {
         $self->enable_warnings && $self->log->warning("show: Net::Libdnet::Intf get failed for device [$this]");
         next;
      }

      print $get->print."\n";
   }

   return 1;
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

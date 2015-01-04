#
# $Id$
#
# network::frame Brik
#
package Metabrik::Network::Frame;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(TODO frame packet network) ],
      attributes => {
         device => [ qw(device) ],
         interface => [ qw(interface_info_hash) ],
      },
      commands => {
         update_interface => [ ],
         from_read => [ qw(frame) ],
         from_hexa => [ ],
         show => [ ],
         mac2eui64 => [ qw(mac_address) ],
         frame => [ qw(layers_list) ],
         arp => [ qw(destination_ipv4_address|OPTIONAL) ],
         eth => [ ],
         ipv4 => [ qw(protocol_id|OPTIONAL) ],
         icmpv4 => [ ],
         echo_icmpv4 => [ ],
      },
      require_modules => {
         'Net::Frame::Simple' => [ ],
         'Net::Frame::Layer::ARP' => [ ],
         'Net::Frame::Layer::ETH' => [ ],
         'Net::Frame::Layer::IPv4' => [ ],
         'Net::Frame::Layer::IPv6' => [ ],
         'Net::Frame::Layer::TCP' => [ ],
         'Net::Frame::Layer::UDP' => [ ],
         'Net::Frame::Layer::ICMPv4' => [ ],
         'Net::Frame::Layer::ICMPv6' => [ ],
         'Metabrik::String::Hexa' => [ ],
         'Metabrik::Network::Device' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device || 'eth0',
      },
   };
}

sub brik_init {
   my $self = shift;

   my $interface = $self->update_interface
      or return $self->log->error("brik_init: update_interface failed, you may not have a global device set");

   $self->interface($interface);

   return $self->SUPER::brik_init;
}

sub update_interface {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;

   my $network_device = Metabrik::Network::Device->new_from_brik($self);

   my $interface = $network_device->get($device)
      or return $self->log->error("update_interface: get failed");

   return $self->interface($interface);
}

sub from_read {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('from_read'));
   }

   if (ref($data) ne 'HASH') {
      return $self->log->error("from_read: data must be a HASHREF");
   }

   if (! exists($data->{raw})
   ||  ! exists($data->{firstLayer})
   ||  ! exists($data->{timestamp})) {
      return $self->log->error("from_read: data must be come from network::read Brik");
   }

   return Net::Frame::Simple->newFromDump($data);
}

sub from_hexa {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('from_hexa'));
   }

   my $string_hexa = Metabrik::String::Hexa->new_from_brik_init($self);

   if (! $string_hexa->is_hexa($data)) {
      return $self->log->error('from_hexa: data is not hexa');
   }

   my $raw = $string_hexa->decode($data)
      or return $self->log->error("from_hexa: decode failed");

   return Net::Frame::Simple->new(raw => $raw, firstLayer => 'ETH');
}

sub show {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('show'));
   }

   if (ref($data) ne 'Net::Frame::Simple') {
      return $self->log->error("show: data must come from from_read Command");
   }

   my $str = $data->print;

   print $str."\n";

   return 1;
}

# http://tools.ietf.org/html/rfc2373
sub mac2eui64 {
   my $self = shift;
   my ($mac) = @_;

   if (! defined($mac)) {
      return $self->log->error($self->brik_help_run('mac2eui64'));
   }

   my @b  = split(':', $mac);
   my $b0 = hex($b[0]) ^ 2;

   return sprintf("fe80::%x%x:%xff:fe%x:%x%x", $b0, hex($b[1]), hex($b[2]),
      hex($b[3]), hex($b[4]), hex($b[5]));
}

# Returns an ARP header with a set of default values
sub arp {
   my $self = shift;
   my ($dst_ip) = @_;

   my $interface = $self->interface;

   $dst_ip ||= '127.0.0.1';

   my $hdr = Net::Frame::Layer::ARP->new(
      #opCode => NF_ARP_OPCODE_REQUEST,  # Default
      srcIp => $interface->{ipv4},
      dstIp => $dst_ip,
      src => $interface->{mac},
   );

   return $hdr;
}

# Returns an Ethernet header with a set of default values
sub eth {
   my $self = shift;

   my $interface = $self->interface;

   my $hdr = Net::Frame::Layer::ETH->new(
      type => 0x0800,  # IPv4
      src => $interface->{mac},
   );

   return $hdr;
}

sub ipv4 {
   my $self = shift;
   my ($protocol) = @_;

   my $interface = $self->interface;

   my $hdr = Net::Frame::Layer::IPv4->new(
      #protocol => NF_IPv4_PROTOCOL_TCP,  # Default
      src => $interface->{ipv4},
   );

   return $hdr;
}

sub icmpv4 {
   my $self = shift;

   my $hdr = Net::Frame::Layer::ICMPv4->new;

   return $hdr;
}

sub echo_icmpv4 {
   my $self = shift;
   my ($data) = @_;

   $data ||= 'echo';

   my $hdr = Net::Frame::Layer::ICMPv4::Echo->new(
      payload => $data,
   );

   return $hdr;
}

sub frame {
   my $self = shift;
   my ($layers) = @_;

   if (! defined($layers)) {
      return $self->log->error($self->brik_help_run('frame'));
   }

   if (ref($layers) ne 'ARRAY') {
      return $self->log->error("frame: Argument must be ARRAY");
   }

   my $request = Net::Frame::Simple->new(
      layers => $layers,
   );

   return $request;
}

1;

__END__

=head1 NAME

Metabrik::Network::Frame - network::frame Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

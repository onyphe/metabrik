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
      tags => [ qw(unstable network frame packet ip tcp udp icmp eth ethernet arp) ],
      attributes => {
         device => [ qw(device) ],
         device_info => [ qw(device_info_hash) ],
      },
      commands => {
         update_device_info => [ ],
         from_read => [ qw(frame) ],
         from_hexa => [ qw(hexa first_layer|OPTIONAL) ],
         from_raw => [ qw(raw first_layer|OPTIONAL) ],
         show => [ ],
         mac2eui64 => [ qw(mac_address) ],
         frame => [ qw(layers_array) ],
         arp => [ qw(destination_ipv4_address|OPTIONAL destination_mac|OPTIONAL) ],
         eth => [ qw(destination_mac|OPTIONAL type|OPTIONAL) ],
         ipv4 => [ qw(destination_ipv4_address|OPTIONAL protocol|OPTIONAL) ],
         tcp => [ qw(destination_port|OPTIONAL source_port|OPTIONAL flags|OPTIONAL) ],
         udp => [ qw(destination_port|OPTIONAL source_port|OPTIONAL payload|OPTIONAL) ],
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

   $self->update_device_info
      or return $self->log->error("brik_init: update_device_info failed, you may not have a global device set");

   return $self->SUPER::brik_init(@_);
}

sub update_device_info {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;

   my $nd = Metabrik::Network::Device->new_from_brik_init($self) or return;

   my $device_info = $nd->get($device)
      or return $self->log->error("update_device_info: get failed");

   $self->log->verbose("update_device_info: updating from device [$device]");

   return $self->device_info($device_info);
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
   my ($data, $first_layer) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('from_hexa'));
   }

   $first_layer ||= 'IPv4';

   my $sh = Metabrik::String::Hexa->new_from_brik_init($self) or return;

   if (! $sh->is_hexa($data)) {
      return $self->log->error('from_hexa: data is not hexa');
   }

   my $raw = $sh->decode($data)
      or return $self->log->error("from_hexa: decode failed");

   my $frame;
   eval {
      $frame = Net::Frame::Simple->new(raw => $raw, firstLayer => $first_layer);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("from_hexa: cannot parse frame, not a $first_layer first layer? [$@]");
   }

   return $frame;
}

sub from_raw {
   my $self = shift;
   my ($raw, $first_layer) = @_;

   if (! defined($raw)) {
      return $self->log->error($self->brik_help_run('from_raw'));
   }

   return $self->from_hexa(unpack('H*', $raw), $first_layer);
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
   my ($dst_ip, $dst_mac) = @_;

   my $device_info = $self->device_info;

   $dst_ip ||= '127.0.0.1';
   $dst_mac ||= '00:00:00:00:00:00';

   my $hdr = Net::Frame::Layer::ARP->new(
      #opCode => NF_ARP_OPCODE_REQUEST,  # Default
      srcIp => $device_info->{ipv4},
      dstIp => $dst_ip,
      src => $device_info->{mac},
      dst => $dst_mac,
   );

   return $hdr;
}

# Returns an Ethernet header with a set of default values
sub eth {
   my $self = shift;
   my ($dst, $type) = @_;

   my $device_info = $self->device_info;

   $dst ||= 'ff:ff:ff:ff:ff:ff'; # Broadcast
   $type ||= 0x0800; # IPv4

   my $hdr = Net::Frame::Layer::ETH->new(
      src => $device_info->{mac},
      dst => $dst,
      type => $type,
   );

   return $hdr;
}

sub ipv4 {
   my $self = shift;
   my ($dst, $protocol) = @_;

   my $device_info = $self->device_info;

   $dst ||= '127.0.0.1';
   $protocol ||= 6;  # TCP

   my $hdr = Net::Frame::Layer::IPv4->new(
      src => $device_info->{ipv4},
      dst => $dst,
      protocol => $protocol,
   );

   return $hdr;
}

sub tcp {
   my $self = shift;
   my ($dst, $src, $flags) = @_;

   $dst ||= 80;
   $src ||= 1025;
   $flags ||= 0x02;   # SYN

   return Net::Frame::Layer::TCP->new(
      dst => $dst,
      src => $src,
      flags => $flags,
   );
}

sub udp {
   my $self = shift;
   my ($dst, $src, $payload) = @_;

   $dst ||= 123;
   $src ||= 1025;
   $payload ||= '';

   return Net::Frame::Layer::UDP->new(
      dst => $dst,
      src => $src,
      length => length($payload),
   )->pack.$payload;
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

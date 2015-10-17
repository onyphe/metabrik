#
# $Id$
#
# network::arp Brik
#
package Metabrik::Network::Arp;
use strict;
use warnings;

use base qw(Metabrik::Network::Frame);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable arp cache poison eui64 discover scan) ],
      attributes => {
         try => [ qw(try_count) ],
         timeout => [ qw(timeout_seconds) ],
         _dnet => [ qw(Net::Libdnet::Arp) ],
      },
      attributes_default => {
         try => 2,
         timeout => 2,
      },
      commands => {
         cache => [ ],
         half_poison => [ ],
         full_poison => [ ],
         mac2eui64 => [ qw(mac_address) ],
         scan => [ qw(subnet|OPTIONAL) ],
         get_ipv4_neighbors => [ qw(subnet|OPTIONAL) ],
         get_ipv6_neighbors => [ qw(subnet|OPTIONAL) ],
         get_mac_neighbors => [ qw(subnet|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Network::Arp' => [ ],
         'Metabrik::Network::Write' => [ ],
         'Metabrik::Network::Read' => [ ],
         'Metabrik::Network::Address' => [ ],
         'Net::Frame::Layer::ARP' => [ ],
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

sub _get_arp_frame {
   my $self = shift;
   my ($dst_ip) = @_;

   my $eth = $self->eth;
   $eth->type(0x0806);  # ARP

   my $arp = $self->arp($dst_ip);
   my $frame = $self->frame([ $eth, $arp ]);

   return $frame;
}

sub scan {
   my $self = shift;
   my ($subnet) = @_;

   if ($< != 0) {
      return $self->log->error("scan: must be root to run");
   }

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my $interface = $self->device_info;

   $subnet ||= $interface->{subnet4};
   if (! defined($subnet)) {
      return $self->log->error($self->brik_help_run('scan'));
   }

   my $arp_cache = $self->cache
      or return $self->log->error("scan: cache failed");

   my $ip_list = $na->ipv4_list($subnet)
      or return $self->log->error("scan: ipv4_list failed");

   my $reply_cache = {};
   my $local_arp_cache = {};
   my @frame_list = ();

   for my $ip (@$ip_list) {
      # We scan ARP for everyone but our own IP
      next if $ip eq $interface->{ipv4};

      # XXX: move to network::arp so there is one place for ARP cache handling
      my $mac;
      if (exists($local_arp_cache->{$ip})) {
         $mac = $local_arp_cache->{$ip};
         $reply_cache->{$ip} = $mac;
      }
      elsif ($mac = $arp_cache->{$ip}) {
         $self->log->verbose("scan: found mac [$mac] for ipv4 [$ip] in ARP cache");
         $local_arp_cache->{$ip} = $mac;
         $reply_cache->{$ip} = $mac;
      }
      else {
         # If it is not in ARP cache yet
         push @frame_list, $self->_get_arp_frame($ip);
      }
   }

   my $nw = Metabrik::Network::Write->new_from_brik_init($self) or return;

   my $write = $nw->open(2, $self->device)
      or return $self->log->error("scan: open failed");

   my $nr = Metabrik::Network::Read->new_from_brik_init($self) or return;
   $nr->rtimeout($self->timeout);

   my $filter = 'arp and src net '.$subnet.' and dst host '.$interface->{ipv4};
   my $read = $nr->open(2, $self->device, $filter)
      or return $self->log->error("scan: open failed");

   # We will send frames 3 times max
   my $try = $self->try;
   for my $t (1..$try) {
      # We send all frames
      for my $r (@frame_list) {
         $self->debug && $self->log->debug($r->print);
         my $dst_ip = $r->ref->{ARP}->dstIp;
         if (! exists($reply_cache->{$dst_ip})) {
            $nw->send($r->raw)
               or $self->log->warning("scan: send failed");
         }
      }

      # Then we wait for all replies until a timeout occurs
      my $h_list = $nr->next_until_timeout;
      for my $h (@$h_list) {
         my $r = $self->from_read($h);
         #$self->log->verbose("scan: read next returned some stuff".$r->print);

         if ($r->ref->{ARP}->opCode != &Net::Frame::Layer::ARP::NF_ARP_OPCODE_REPLY) {
            next;
         }

         my $src_ip = $r->ref->{ARP}->srcIp;
         if (! exists($reply_cache->{$src_ip})) {
            my $mac = $r->ref->{ARP}->src;
            $self->log->info("scan: received mac [$mac] for ipv4 [$src_ip]");
            $reply_cache->{$src_ip} = $r->ref->{ARP}->src;

            # Put it in ARP cache table for next round
            $local_arp_cache->{$src_ip} = $mac;
         }
      }

      $nr->reset_timeout;
   }

   $nw->close;
   $nr->close;

   my %results = ();
   for (keys %$reply_cache) {
      my $mac = $reply_cache->{$_};
      my $ip4 = $_;
      my $ip6 = $self->mac2eui64($mac);
      $self->log->verbose(sprintf("%-16s => %s  [%s]", $ip4, $mac, $ip6));
      $results{by_ipv4}{$ip4} = { ipv6 => $ip6, mac => $mac, ipv4 => $ip4 };
      $results{by_mac}{$mac} = { ipv6 => $ip6, mac => $mac, ipv4 => $ip4 };
      $results{by_ipv6}{$ip6} = { ipv6 => $ip6, mac => $mac, ipv4 => $ip4 };
   }

   return \%results;
}

sub get_ipv4_neighbors {
   my $self = shift;
   my ($subnet) = @_;

   my $scan = $self->scan($subnet) or return;
   my $ipv4 = $scan->{by_ipv4};
   if (! defined($ipv4)) {
      return $self->log->info("get_ipv4_neighbors: no IPv4 neighbor found");
   }

   return $ipv4;
}

sub get_ipv6_neighbors {
   my $self = shift;
   my ($subnet) = @_;

   my $scan = $self->scan($subnet) or return;
   my $ipv6 = $scan->{by_ipv6};
   if (! defined($ipv6)) {
      return $self->log->info("get_ipv6_neighbors: no IPv6 neighbor found");
   }

   return $ipv6;
}

sub get_mac_neighbors {
   my $self = shift;
   my ($subnet) = @_;

   my $scan = $self->scan($subnet) or return;
   my $mac = $scan->{by_mac};
   if (! defined($mac)) {
      return $self->log->info("get_mac_neighbors: no MAC neighbor found");
   }

   return $mac;
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

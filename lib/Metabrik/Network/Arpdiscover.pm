#
# $Id$
#
package Metabrik::Network::Arpdiscover;
use strict;
use warnings;

use base qw(Metabrik::Network::Frame);

use Net::Frame::Layer::ARP qw(:consts);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable arp scan discover) ],
      attributes => {
         try => [ qw(try_count) ],
         timeout => [ qw(timeout_seconds) ],
      },
      attributes_default => {
         try => 2,
         timeout => 2,
      },
      commands => {
         scan => [ qw(subnet|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Network::Arp' => [ ],
         'Metabrik::Network::Write' => [ ],
         'Metabrik::Network::Read' => [ ],
         'Metabrik::Network::Address' => [ ],
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

   my $network_arp = Metabrik::Network::Arp->new_from_brik_init($self) or return;
   my $network_address = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my $interface = $self->interface;

   $subnet ||= $interface->{subnet};

   my $arp_cache = $network_arp->cache
      or return $self->log->error("scan: cache failed");

   my $ip_list = $network_address->ipv4_list($subnet)
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

   my $network_write = Metabrik::Network::Write->new_from_brik_init($self) or return;

   my $write = $network_write->open(2, $self->device)
      or return $self->log->error("scan: open failed");

   my $network_read = Metabrik::Network::Read->new_from_brik_init($self) or return;
   $network_read->rtimeout($self->timeout);

   my $filter = 'arp and src net '.$subnet.' and dst host '.$interface->{ipv4};
   my $read = $network_read->open(2, $self->device, $filter)
      or return $self->log->error("scan: open failed");

   # We will send frames 3 times max
   my $try = $self->try;
   for my $t (1..$try) {
      # We send all frames
      for my $r (@frame_list) {
         $self->debug && $self->log->debug($r->print);
         my $dst_ip = $r->ref->{ARP}->dstIp;
         if (! exists($reply_cache->{$dst_ip})) {
            $network_write->send($r->raw)
               or $self->log->warning("scan: send failed");
         }
      }

      # Then we wait for all replies until a timeout occurs
      my $h_list = $network_read->next_until_timeout;
      for my $h (@$h_list) {
         my $r = $self->from_read($h);
         #$self->log->verbose("scan: read next returned some stuff".$r->print);

         if ($r->ref->{ARP}->opCode != NF_ARP_OPCODE_REPLY) {
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

      $network_read->reset_timeout;
   }

   $network_write->close;
   $network_read->close;

   my %results = ();
   for (keys %$reply_cache) {
      my $mac = $reply_cache->{$_};
      my $ip4 = $_;
      my $ip6 = $network_arp->mac2eui64($mac);
      $self->log->verbose(sprintf("%-16s => %s  [%s]", $ip4, $mac, $ip6));
      $results{$ip4} = { ipv6 => $ip6, mac => $mac, ipv4 => $ip4 };
      $results{$mac} = { ipv6 => $ip6, mac => $mac, ipv4 => $ip4 };
      $results{$ip6} = { ipv6 => $ip6, mac => $mac, ipv4 => $ip4 };
   }

   return \%results;
}

1;

__END__

=head1 NAME

Metabrik::Network::Arpdiscover - network::arpdiscover Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

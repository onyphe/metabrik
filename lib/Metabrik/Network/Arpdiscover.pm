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
      },
      attributes_default => {
         try => 2,
      },
      commands => {
         scan => [ ],
      },
      require_used => {
         'network::arp' => [ ],
         'network::write' => [ ],
         'network::read' => [ ],
         'network::address' => [ ],
      },
      #require_modules => {
      #},
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

   my $context = $self->context;

   my $arp_cache = $context->run('network::arp', 'cache')
      or return $self->log->error("scan: network::arp cache failed");

   my $interface = $self->interface;

   $subnet ||= $interface->{subnet};

   $context->set('network::address', 'subnet', $subnet);
   my $ip_list = $context->run('network::address', 'iplist')
      or return $self->log->error("scan: network::address iplist failed");

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

   $context->save_state('network::write');

   $context->set('network::write', 'device', $self->device);
   $context->set('network::write', 'layer', 2);
   my $write = $context->run('network::write', 'open')
      or return $self->log->error("scan: network::write open failed");

   $context->save_state('network::read');

   $context->set('network::read', 'device', $self->device);
   $context->set('network::read', 'layer', 2);
   my $filter = 'arp and src net '.$subnet.' and dst host '.$interface->{ipv4};
   $context->set('network::read', 'filter', $filter);
   my $read = $context->run('network::read', 'open')
      or return $self->log->error("scan: network::read open failed");

   # We will send frames 3 times max
   my $try = $self->try;
   for my $t (1..$try) {
      # We send all frames
      for my $r (@frame_list) {
         $self->debug && $self->log->debug($r->print);
         my $dst_ip = $r->ref->{ARP}->dstIp;
         if (! exists($reply_cache->{$dst_ip})) {
            $context->run('network::write', 'send', $r->raw)
               or $self->log->warning("scan: network::write send failed");
         }
      }

      # Then we wait for all replies until a timeout occurs
      my $h_list = $context->run('network::read', 'next_until_timeout');
      for my $h (@$h_list) {
         my $r = $self->from_read($h);
         #$self->log->verbose("scan: read next returned some stuff".$r->print);

         if ($r->ref->{ARP}->opCode != NF_ARP_OPCODE_REPLY) {
            next;
         }

         my $src_ip = $r->ref->{ARP}->srcIp;
         if (! exists($reply_cache->{$src_ip})) {
            my $mac = $r->ref->{ARP}->src;
            $self->log->info("scan2: received mac [$mac] for ipv4 [$src_ip]");
            $reply_cache->{$src_ip} = $r->ref->{ARP}->src;

            # Put it in ARP cache table for next round
            $local_arp_cache->{$src_ip} = $mac;
         }
      }

      $context->run('network::read', 'reset_timeout');
   }

   $context->run('network::write', 'close');
   $context->run('network::read', 'close');

   $context->restore_state('network::write');
   $context->restore_state('network::read');

   for (keys %$reply_cache) {
      $self->log->verbose(sprintf("%-16s => %s", $_, $reply_cache->{$_}));
   }

   return $reply_cache;
}

1;

__END__

=head1 NAME

Metabrik::Network::Arpdiscover - network::arpdiscover Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

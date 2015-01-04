#
# $Id$
#
# network::icmp Brik
#
package Metabrik::Network::Icmp;
use strict;
use warnings;

use base qw(Metabrik::Network::Frame);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable icmp ping redirect doubleredirect mitm) ],
      commands => {
         ping => [ qw(ipv4_address) ],
         half_poison => [ ],
         full_poison => [ ],
      },
      require_modules => {
         'Metabrik::Network::Write' => [ ],
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

sub ping {
   my $self = shift;
   my ($target) = @_;

   if (! defined($target)) {
      return $self->log->error($self->brik_help_run('ping'));
   }

   my $ipv4 = $self->ipv4;
   $ipv4->dst($target);
   $ipv4->protocol(0x01);  # ICMPv4

   my $icmpv4 = $self->icmpv4;

   my $echo1 = $self->echo_icmpv4;
   $echo1->identifier(1);
   my $echo2 = $self->echo_icmpv4;
   $echo2->identifier(2);
   my $echo3 = $self->echo_icmpv4;
   $echo3->identifier(3);

   my $frame1 = $self->frame([ $ipv4, $icmpv4, $echo1 ]);
   my $frame2 = $self->frame([ $ipv4, $icmpv4, $echo2 ]);
   my $frame3 = $self->frame([ $ipv4, $icmpv4, $echo3 ]);

   my $write = Metabrik::Network::Write->new_from_brik($self);

   # We must use different Net::Frame::Simple objects so recv() method will work
   for my $f ($frame1, $frame2, $frame3) {
      my $r = $write->fnsend_reply($f)
         or return $self->log->error("ping: network::write fnsend_reply failed");
      if (defined($r)) {
         print $r->print."\n";
      }
      sleep(1);
   }

   return 1;
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

Metabrik::Network::Icmp - network::icmp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

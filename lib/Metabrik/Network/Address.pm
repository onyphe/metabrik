#
# $Id$
#
# network::address Brik
#
package Metabrik::Network::Address;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable address netmask) ],
      attributes => {
         subnet => [ qw(subnet) ],
      },
      commands => {
         match => [ qw(ipv4_address subnet|OPTIONAL) ],
         ipv4_list => [ qw(subnet|OPTIONAL) ],
         network_address => [ qw(subnet|OPTIONAL) ],
         broadcast_address => [ qw(subnet|OPTIONAL) ],
         range_to_cidr => [ qw(first_address last_address) ],
      },
      require_modules => {
         'Net::Netmask' => [ ],
      },
   };
}

sub match {
   my $self = shift;
   my ($ip, $subnet) = @_;

   $subnet ||= $self->subnet;
   if (! defined($subnet)) {
      return $self->log->error($self->brik_help_run('match'));
   }

   my $block = Net::Netmask->new($subnet);

   if ($block->match($ip)) {
      $self->log->info("match: $ip is in the same subnet as $subnet");
      return 1;
   }
   else {
      $self->log->info("match: $ip is NOT in the same subnet as $subnet");
      return 0;
   }

   return;
}

sub ipv4_list {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   if (! defined($subnet)) {
      return $self->log->error($self->brik_help_run('ipv4_list'));
   }

   my $block = Net::Netmask->new($subnet);

   my @ip_list = $block->enumerate;

   return \@ip_list;
}

sub network_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   if (! defined($subnet)) {
      return $self->log->error($self->brik_help_run('network_address'));
   }

   my $block = Net::Netmask->new($subnet);
   my $first = $block->first;

   return $first;
}

sub broadcast_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   if (! defined($subnet)) {
      return $self->log->error($self->brik_help_run('broadcast_address'));
   }

   my $block = Net::Netmask->new($subnet);
   my $last = $block->last;

   return $last;
}

sub range_to_cidr {
   my $self = shift;
   my ($first, $last) = @_;

   if (! defined($first) || ! defined($last)) {
      return $self->log->error($self->brik_help_run('range_to_subnet'));
   }

   my @blocks = Net::Netmask::range2cidrlist($first, $last);

   my @res = ();
   for my $block (@blocks) {
      my $new = Net::Netmask->new($block);
      push @res, $new->base."/".$new->bits;
   }

   return \@res;
}

1;

__END__

=head1 NAME

Metabrik::Network::Address - network::address Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

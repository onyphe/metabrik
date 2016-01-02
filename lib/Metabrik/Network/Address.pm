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
      tags => [ qw(unstable netmask) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         subnet => [ qw(subnet) ],
      },
      commands => {
         match => [ qw(ipv4_address subnet|OPTIONAL) ],
         network_address => [ qw(subnet|OPTIONAL) ],
         broadcast_address => [ qw(subnet|OPTIONAL) ],
         netmask_address => [ qw(subnet|OPTIONAL) ],
         netmask_to_cidr => [ qw(netmask) ],
         range_to_cidr => [ qw(first_ip_address last_ip_address) ],
         is_ipv4 => [ qw(ipv4_address) ],
         is_ipv6 => [ qw(ipv6_address) ],
         is_ip => [ qw(ip_address) ],
         is_rfc1918 => [ qw(ip_address) ],
         ipv4_list => [ qw(subnet|OPTIONAL) ],
         ipv6_list => [ qw(subnet|OPTIONAL) ],
         count_ipv4 => [ qw(subnet|OPTIONAL) ],
         get_ipv4_cidr => [ qw(subnet|OPTIONAL) ],
         is_ipv4_subnet => [ qw(subnet|OPTIONAL) ],
         merge_cidr => [ qw($cidr_list) ],
      },
      require_modules => {
         'Net::Netmask' => [ ],
         'Net::IPv4Addr' => [ ],
         'Net::IPv6Addr' => [ ],
         'NetAddr::IP' => [ ],
         'Net::CIDR' => [ ],
      },
   };
}

sub match {
   my $self = shift;
   my ($ip, $subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('match', $subnet) or return;

   if (! $self->is_ip($ip) || ! $self->is_ip($subnet)) {
      return $self->log->error("match: invalid format for ip [$ip] or subnet [$subnet]");
   }

   if (Net::CIDR::cidrlookup($ip, $subnet)) {
      $self->log->verbose("match: $ip is in the same subnet as $subnet");
      return 1;
   }
   else {
      $self->log->verbose("match: $ip is NOT in the same subnet as $subnet");
      return 0;
   }

   return 0;
}

sub network_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('network_address', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("network_address: invalid format [$subnet], not an IPv4 address");
   }

   my ($address) = Net::IPv4Addr::ipv4_network($subnet);

   return $address;
}

sub broadcast_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('broadcast_address', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("broadcast_address: invalid format [$subnet], not an IPv4 address");
   }

   my ($address) = Net::IPv4Addr::ipv4_broadcast($subnet);

   return $address;
}

sub netmask_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('netmask_address', $subnet) or return;

   # XXX: Not IPv6 compliant
   my $block = Net::Netmask->new($subnet);
   my $mask = $block->mask;

   return $mask;
}

sub range_to_cidr {
   my $self = shift;
   my ($first, $last) = @_;

   $self->brik_help_run_undef_arg('range_to_cidr', $first) or return;
   $self->brik_help_run_undef_arg('range_to_cidr', $last) or return;

   # IPv4 and IPv6 compliant
   my @list = Net::CIDR::range2cidr("$first-$last");

   return \@list;
}

sub is_ip {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ip', $ip) or return;

   (my $local = $ip) =~ s/\/\d+$//;

   if (Net::CIDR::cidrvalidate($local)) {
      return 1;
   }

   return 0;
}

sub is_rfc1918 {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_rfc1918', $ip) or return;

   if (! $self->is_ipv4($ip)) {
      return $self->log->error("is_rfc1918: invalid format [$ip]");
   }

   (my $local = $ip) =~ s/\/\d+$//;

   my $new = NetAddr::IP->new($local);
   my $is;
   eval {
      $is = $new->is_rfc1918;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_rfc1918: is_rfc1918 failed for [$local] with error [$@]");
   }

   return $is ? 1 : 0;
}

sub is_ipv4 {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ipv4', $ip) or return;

   (my $local = $ip) =~ s/\/\d+$//;

   if ($local =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      return 1;
   }

   return 0;
}

sub is_ipv6 {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ipv6', $ip) or return;

   (my $local = $ip) =~ s/\/\d+$//;

   if ($local =~ /^[0-9a-f:\/]+$/i) {
      eval {
         my $x = Net::IPv6Addr::ipv6_parse($local);
      };
      if (! $@) {
         return 1;
      }
   }

   return 0;
}

sub netmask_to_cidr {
   my $self = shift;
   my ($netmask) = @_;

   $self->brik_help_run_undef_arg('netmask_to_cidr', $netmask) or return;

   # We use a fake address, cause we are only interested in netmask
   my $cidr = Net::CIDR::addrandmask2cidr("127.0.0.0", $netmask);

   my ($size) = $cidr =~ m{/(\d+)$};

   return $size;
}

sub ipv4_list {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('ipv4_list', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("ipv4_list: invalid format [$subnet], not IPv4");
   }

   # This will allow handling of IPv4 /12 networks (~ 1_000_000 IP addresses)
   NetAddr::IP::netlimit(20);

   my $a = $self->network_address($subnet) or return;
   my $m = $self->netmask_address($subnet) or return;

   my $ip = NetAddr::IP->new($a, $m);
   my $r;
   eval {
      $r = $ip->hostenumref;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("ipv4_list: hostenumref failed for [$a] [$m] with error [$@]");
   }

   my @list = ();
   for my $ip (@$r) {
      push @list, $ip->addr;
   }

   return \@list;
}

sub ipv6_list {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('ipv6_list', $subnet) or return;

   if (! $self->is_ipv6($subnet)) {
      return $self->log->error("ipv6_list: invalid format [$subnet], not IPv6");
   }

   # Makes IPv6 fully lowercase
   eval("use NetAddr::IP qw(:lower);");

   # Will allow building a list of ~ 1_000_000 IP addresses
   NetAddr::IP::netlimit(20);

   my $ip = NetAddr::IP->new($subnet);
   my $r;
   eval {
      $r = $ip->hostenumref;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("ipv6_list: hostenumref failed for [$subnet] with error [$@]");
   }

   my @list = ();
   for my $ip (@$r) {
      push @list, $ip->addr;
   }

   return \@list;
}

sub get_ipv4_cidr {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('get_ipv4_cidr', $subnet) or return;

   my ($cidr) = $subnet =~ m{/(\d+)$};
   if (! defined($cidr)) {
      return $self->log->error("get_ipv4_cidr: no CIDR mask found");
   }

   if ($cidr < 0 || $cidr > 32) {
      return $self->log->error("get_ipv4_cidr: invalid CIDR mask [$cidr]");
   }

   return $cidr;
}

sub count_ipv4 {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('count_ipv4', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("count_ipv4: invalid format [$subnet], not IPv4");
   }

   my $cidr = $self->get_ipv4_cidr($subnet) or return;

   return 2 ** (32 - $cidr);
}

sub is_ipv4_subnet {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('is_ipv4_subnet', $subnet) or return;

   my ($address, $cidr) = $subnet =~ m{^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d+)$};
   if (! defined($address) || ! defined($cidr)) {
      $self->log->verbose("is_ipv4_subnet: not a subnet [$subnet]");
      return 0;
   }

   if ($cidr < 0 || $cidr > 32) {
      $self->log->verbose("is_ipv4_subnet: not a valid CIDR mask [$cidr]");
      return 0;
   }

   return 1;
}

sub merge_cidr {
   my $self = shift;
   my ($list) = @_;

   $self->brik_help_run_undef_arg('merge_cidr', $list) or return;
   $self->brik_help_run_invalid_arg('merge_cidr', $list, 'ARRAY') or return;

   my @list = Net::CIDR::cidradd(@$list) or return;

   return \@list;
}

1;

__END__

=head1 NAME

Metabrik::Network::Address - network::address Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id$
#
# network::route Brik
#
package Metabrik::Network::Route;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
      },
      commands => {
         list => [ ],
         show => [ ],
         is_router_ipv4 => [ qw(device|OPTIONAL) ],
         enable_router_ipv4 => [ qw(device|OPTIONAL) ],
         disable_router_ipv4 => [ qw(device|OPTIONAL) ],
         default_device => [ qw(ip_address|OPTIONAL) ],
         default_ipv4_gateway => [ qw(device|OPTIONAL) ],
         default_ipv6_gateway => [ qw(device|OPTIONAL) ],
      },
      require_modules => {
         'Net::Routing' => [ ],
         'Metabrik::Network::Device' => [ ],
         'Metabrik::Shell::Command' => [ ],
      },
      require_binaries => {
         'sysctl' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub show {
   my $self = shift;

   $self->log->info("show: IPv4 network routes:");

   my $nr4 = Net::Routing->new(
      target => Net::Routing::NR_TARGET_ALL(),
      family => Net::Routing::NR_FAMILY_INET4(),
   ) or return $self->log->error("show: Net::Routing new failed: [$Net::Routing::Error]");
   $nr4->list;

   print "\n";

   $self->log->info("show: IPv6 network routes:");

   my $nr6 = Net::Routing->new(
      target => Net::Routing::NR_TARGET_ALL(),
      family => Net::Routing::NR_FAMILY_INET6(),
   ) or return $self->log->error("show: Net::Routing new failed: [$Net::Routing::Error]");
   $nr6->list;

   return 1;
}

sub list {
   my $self = shift;

   my $nr4 = Net::Routing->new(
      target => Net::Routing::NR_TARGET_ALL(),
      family => Net::Routing::NR_FAMILY_INET4(),
   ) or return $self->log->error("list: Net::Routing new failed: [$Net::Routing::Error]");
   my $route4 = $nr4->get || [];

   for (@$route4) {
      $_->{family} = 'inet4';
   }

   my $nr6 = Net::Routing->new(
      target => Net::Routing::NR_TARGET_ALL(),
      family => Net::Routing::NR_FAMILY_INET6(),
   ) or return $self->log->error("list: Net::Routing new failed: [$Net::Routing::Error]");
   my $route6 = $nr6->get || [];

   for (@$route6) {
      $_->{family} = 'inet6';
   }

   return [ @$route4, @$route6 ];
}

sub default_device {
   my $self = shift;
   my ($ip_address) = @_;

   my $nd = Metabrik::Network::Device->new_from_brik_init($self) or return;
   return $nd->default($ip_address);
}

sub default_ipv4_gateway {
   my $self = shift;
   my ($device) = @_;

   $device ||= '';

   my $routes = $self->list or return;
   for (@$routes) {
      next unless (length($device) && $_->{interface} eq $device || ! length($device));
      if ($_->{family} eq 'inet4' && $_->{default}) {
         return $_->{gateway};
      }
   }

   if (length($device)) {
      $self->log->info("default_ipv4_gateway: no default gateway found for device [$device]");
   }
   else {
      $self->log->info("default_ipv4_gateway: no default gateway found");
   }

   return 0;
}

sub default_ipv6_gateway {
   my $self = shift;
   my ($device) = @_;

   $device ||= '';

   my $routes = $self->list or return;
   for (@$routes) {
      next unless (length($device) && $_->{interface} eq $device || ! length($device));
      if ($_->{family} eq 'inet6' && $_->{default}) {
         return $_->{gateway};
      }
   }

   if (length($device)) {
      $self->log->info("default_ipv6_gateway: no default gateway found for device [$device]");
   }
   else {
      $self->log->info("default_ipv6_gateway: no default gateway found");
   }

   return 0;
}

sub is_router_ipv4 {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   if (! defined($device)) {
      return $self->log->error($self->brik_help_run('is_router_ipv4'));
   }

   my $command = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   $command->as_matrix(0);
   $command->as_array(0);
   $command->capture_stderr(1);

   my $cmd = "sysctl net.ipv4.conf.$device.forwarding";
   chomp(my $line = $command->capture($cmd));

   $self->log->verbose("is_router_ipv4: cmd [$cmd]");
   $self->log->verbose("is_router_ipv4: returned [$line]");

   my @toks = split(/\s+/, $line);

   my $is_router = $toks[-1];

   $self->log->info("is_router_ipv4: ".($is_router ? "YES" : "NO"));

   return $is_router;
}

sub enable_router_ipv4 {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   if (! defined($device)) {
      return $self->log->error($self->brik_help_run('enable_router_ipv4'));
   }

   my $command = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   $command->as_matrix(0);
   $command->as_array(0);
   $command->capture_stderr(1);

   my $cmd = "sudo sysctl -w net.ipv4.conf.$device.forwarding=1";
   chomp(my $line = $command->capture($cmd));

   $self->log->verbose("enable_router_ipv4: cmd [$cmd]"); 
   $self->log->verbose("enable_router_ipv4: returned [$line]");

   my @toks = split(/\s+/, $line);

   my $is_router = $toks[-1];

   $self->log->info("enable_router_ipv4: ".($is_router ? "YES" : "NO"));

   return $is_router;
}

sub disable_router_ipv4 {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   if (! defined($device)) {
      return $self->log->error($self->brik_help_run('disable_router_ipv4'));
   }

   my $command = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   $command->as_matrix(0);
   $command->as_array(0);
   $command->capture_stderr(1);

   my $cmd = "sudo sysctl -w net.ipv4.conf.$device.forwarding=0";
   chomp(my $line = $command->capture($cmd));

   $self->log->verbose("disable_router_ipv4: cmd [$cmd]");
   $self->log->verbose("disable_router_ipv4: returned [$line]");

   my @toks = split(/\s+/, $line);

   my $is_router = $toks[-1];

   $self->log->info("disable_router_ipv4: ".($is_router ? "YES" : "NO"));

   return $is_router;
}

1;

__END__

=head1 NAME

Metabrik::Network::Route - network::route Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

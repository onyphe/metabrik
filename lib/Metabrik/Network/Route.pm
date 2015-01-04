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
      tags => [ qw(unstable route) ],
      attributes => {
         _dnet => [ qw(Net::Libdnet::Route) ],
      },
      commands => {
         list => [ ],
         show => [ ],
         is_router_ipv4 => [ ],
         enable_router_ipv4 => [ ],
         disable_router_ipv4 => [ ],
      },
      require_modules => {
         'Net::Libdnet::Route' => [ ],
         'Metabrik::Shell::Command' => [ ],
      },
      require_binaries => {
         'sysctl' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $dnet = Net::Libdnet::Route->new
      or return $self->log->error("can't create Net::Libdnet::Route object");

   $self->_dnet($dnet);

   return $self->SUPER::brik_init;
}

sub _display {
   my ($entry, $data) = @_;

   my $buf = sprintf("%-30s %-30s", $entry->{route_dst}, $entry->{route_gw});
   print "$buf\n";

   return $buf;
}

sub show {
   my $self = shift;

   printf("%-30s %-30s\n", 'Destination', 'Gateway');
   my $data = '';
   $self->_dnet->loop(\&_display, \$data);

   return 1;
}

sub _get_list {
   my ($entry, $data) = @_;

   # We may have multiple routes to the same destination.
   # By destination lookup
   push @{$data->{destination}->{$entry->{route_dst}}}, {
      destination => $entry->{route_dst},
      gateway => $entry->{route_gw},
   };
   # By gateway lookup
   push @{$data->{gateway}->{$entry->{route_gw}}}, {
      destination => $entry->{route_dst},
      gateway => $entry->{route_gw},
   };

   return $data;
}

sub list {
   my $self = shift;

   my $data = {};
   $self->_dnet->loop(\&_get_list, $data);

   return $data;
}

sub is_router_ipv4 {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->global->device;

   my $command = Metabrik::Shell::Command->new;
   $command->as_matrix(0);
   $command->as_array(0);
   $command->capture_stderr(1);

   $command->brik_init or return $self->log->error("is_router: shell::command brik_init failed");

   my $cmd = "sysctl net.ipv4.conf.".$device.".forwarding";
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

   $device ||= $self->global->device;

   my $command = Metabrik::Shell::Command->new;
   $command->as_matrix(0);
   $command->as_array(0);
   $command->capture_stderr(1);

   $command->brik_init or return $self->log->error("enable_router_ipv4: shell::command brik_init failed");

   my $cmd = "sysctl -w net.ipv4.conf.".$device.".forwarding=1";
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

   $device ||= $self->global->device;

   my $command = Metabrik::Shell::Command->new;
   $command->as_matrix(0);
   $command->as_array(0);
   $command->capture_stderr(1);

   $command->brik_init or return $self->log->error("disable_router_ipv4: shell::command brik_init failed");

   my $cmd = "sysctl -w net.ipv4.conf.".$device.".forwarding=0";
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

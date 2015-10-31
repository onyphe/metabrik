#
# $Id$
#
# server::tcp Brik
#
package Metabrik::Server::Tcp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable server tcp socket netcat) ],
      attributes => {
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         _poe_kernel => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => '127.0.0.1',
         port => 8888,
      },
      commands => {
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL) ],
      },
      require_modules => {
         'POE::Kernel' => [ ],
         'POE::Component::Server::TCP' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

sub sig_int {
  my $self = shift;

   my $restore = $SIG{INT};

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("sig_int: INT caught");

      my $kernel = $self->_poe_kernel;
      $kernel->stop;

      $SIG{INT} = $restore;
      return 1;
   };

   return 1;
}

sub start {
   my $self = shift;
   my ($hostname, $port, $root) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   if ($port !~ /^\d+$/) {
      return $self->log->error("start: port [$port] must be an integer");
   }
   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ip($hostname)) {
      return $self->log->error("start: hostname [$hostname] must be an IP address");
   }

   use POE qw(Component::Server::TCP);

   POE::Component::Server::TCP->new(
      Port => $port,
      Address => $hostname,
      ClientConnected => sub {
         my $heap = $_[HEAP];
         $self->log->verbose("start: connection from [".$heap->{remote_ip}."]:".$heap->{remote_port});
         $self->sig_int; # We have to reharm the signal
      },
      ClientInput => sub {
         my $input = $_[ARG0];
         my $client = $_[HEAP]{client};
         print "$input\n";   # Just echo on server console what client said
         $client->put("OK"); # And said OK to client
      },
      ClientDisconnected => sub {
         my $heap = $_[HEAP];
         $self->log->verbose("start: disconnection from [".$heap->{remote_ip}."]:".$heap->{remote_port});
      }
   );

   $self->log->error("start: starting server on [$hostname]:$port");

   my $kernel = POE::Kernel->new;
   $self->_poe_kernel($kernel);

   $self->sig_int;
   $self->_poe_kernel->run;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Server::Tcp - server::tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

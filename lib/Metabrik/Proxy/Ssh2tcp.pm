#
# $Id$
#
# proxy::ssh2tcp Brik
#
package Metabrik::Proxy::Ssh2tcp;
use strict;
use warnings;

use base qw(Metabrik::Client::Ssh);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable proxy ssh tcp ssh2tcp socket netcat) ],
      attributes => {
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         ssh_hostname => [ qw(ssh_hostname) ],
         ssh_port => [ qw(ssh_port) ],
         remote_hostname => [ qw(remote_hostname) ],
         remote_port => [ qw(remote_port) ],
         st => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => '127.0.0.1',
         port => 8888,
      },
      commands => {
         start => [ qw(ssh_hostname|OPTIONAL ssh_port|OPTIONAL remote_hostname|OPTIONAL remote_port|OPTIONAL) ],
         is_started => [ ],
         stop => [ ],
      },
      require_modules => {
         'Metabrik::Client::Openssh' => [ ],
         'Metabrik::Network::Address' => [ ],
         'Metabrik::Server::Tcp' => [ ],
         'Metabrik::System::Process' => [ ],
      },
   };
}

sub _handle_sigint {
   my $self = shift;

   my $restore = $SIG{INT};

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("brik_init: INT caught");
      $SIG{INT} = $restore;
      $self->stop;
      return 1;
   };

   return 1;
}

sub brik_init {
   my $self = shift;

   $self->_handle_sigint;

   return $self->SUPER::brik_init(@_);
}

sub is_started {
   my $self = shift;

   if (defined($self->st)) {
      return 1;
   }

   return 0;
}

sub start {
   my $self = shift;
   my ($ssh_hostname, $ssh_port, $remote_hostname, $remote_port) = @_;

   my $hostname = $self->hostname;
   my $port = $self->port;
   $remote_hostname ||= $self->remote_hostname;
   $remote_port ||= $self->remote_port;
   $ssh_hostname ||= $self->ssh_hostname;
   $ssh_port ||= $self->ssh_port;
   if (! defined($ssh_hostname)) {
      return $self->log->error($self->brik_help_run('start'));
   }
   if (! defined($ssh_port)) {
      return $self->log->error($self->brik_help_run('start'));
   }
   if (! defined($remote_hostname)) {
      return $self->log->error($self->brik_help_run('start'));
   }
   if (! defined($remote_port)) {
      return $self->log->error($self->brik_help_run('start'));
   }
   if ($port !~ /^\d+$/) {
      return $self->log->error("start: port [$port] must be an integer");
   }
   if ($ssh_port !~ /^\d+$/) {
      return $self->log->error("start: ssh_port [$ssh_port] must be an integer");
   }
   if ($remote_port !~ /^\d+$/) {
      return $self->log->error("start: remote_port [$remote_port] must be an integer");
   }
   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ip($hostname)) {
      return $self->log->error("start: hostname [$hostname] must be an IP address");
   }
   # ssh_hostname can actually be a hostname
   if (! $na->is_ip($remote_hostname)) {
      return $self->log->error("start: remote_hostname [$remote_hostname] must be an IP address");
   }

   $self->log->verbose("start: connecting to SSH [$ssh_hostname]:$ssh_port");

   my $so = Metabrik::Client::Openssh->new_from_brik_init($self) or return;
   $so->connect($ssh_hostname, $ssh_port) or return;

   my $st = Metabrik::Server::Tcp->new_from_brik_init($self) or return;
   my $server = $st->start or return;
   my $select = $st->select;
   my $clients = $st->clients;

   $self->st($st);

   while (1) {
      last if ! $self->is_started;  # Used to stop the process on SIGINT

      if (my $ready = $st->wait_readable) {
         for my $sock (@$ready) {
            my ($id, $this_client, $this_tunnel) = $self->_get_tunnel_from_sock($clients, $sock);
            if ($sock == $server) {
               $self->log->verbose("start: server socket ready");
               my $client = $st->accept;

               $self->log->verbose("start: new connection from [".
                  $client->{ipv4}."]:".$client->{port});

               my $tunnel = $so->open_tunnel($remote_hostname, $remote_port) or return;
               $select->add($tunnel);
               $client->{tunnel} = $tunnel;

               $self->log->verbose("start: tunnel opened to [$remote_hostname]:$remote_port");
            }
            else {
               if ($sock == $this_client) { # Client sent something
                  my $buf = $st->read($this_client);
                  if (! defined($buf)) {
                     $self->log->verbose("start: client disconnected");
                     $select->remove($this_client);
                  }
                  else {
                     $self->log->verbose("start: read from client [".length($buf)."]");
                     $self->log->verbose("start: write to tunnel [".length($buf)."]");
                     $this_tunnel->syswrite($buf);
                  }
               }
               elsif ($sock == $this_tunnel) {
                  my $buf = $st->read($this_tunnel);
                  if (! defined($buf)) {
                     # If tunnel is disconnected, we can wipe the full connecting client state.
                     # And only at that time.
                     $self->log->verbose("start: tunnel disconnected");
                     $select->remove($this_tunnel);
                     close($this_tunnel);
                     $st->client_disconnected($id);
                  }
                  else {
                     $self->log->verbose("start: read from tunnel [".length($buf)."]");
                     $self->log->verbose("start: write to client [".length($buf)."]");
                     $this_client->syswrite($buf);
                  }
               }
            }
         }
      }
   }

   return 1;
}

sub stop {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->verbose("stop: not started");
   }

   my $st = $self->st;

   # server::tcp know nothing about tunnels, we have to clean by ourselves
   my $clients = $st->clients;
   for my $this (keys %$clients) {
      close($clients->{$this}{tunnel});
      $self->log->verbose("stop: tunnel for client [$this] closed");
   }

   $st->stop;

   $self->_handle_sigint;  # Reharm the signal

   $self->st(undef);

   return 1;
}

sub _get_tunnel_from_sock {
   my $self = shift;
   my ($clients, $sock) = @_;

   my $client;
   my $this_client;
   my $this_tunnel;
   for my $k (keys %$clients) {
      if ($sock == $clients->{$k}{socket} || $sock == $clients->{$k}{tunnel}) {
         $client = $k;
         $this_client = $clients->{$k}{socket};
         $this_tunnel = $clients->{$k}{tunnel};
         last;
      }
   }

   return ( $client, $this_client, $this_tunnel );
}

1;

__END__

=head1 NAME

Metabrik::Proxy::Ssh2tcp - proxy::ssh2tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

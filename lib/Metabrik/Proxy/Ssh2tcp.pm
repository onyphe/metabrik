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
         _poe_kernel => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => '127.0.0.1',
         port => 8888,
      },
      commands => {
         start => [ qw(ssh_hostname|OPTIONAL ssh_port|OPTIONAL remote_hostname|OPTIONAL remote_port|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Openssh' => [ ],
         'Metabrik::Network::Address' => [ ],
         'Metabrik::Server::Tcp' => [ ],
         'Metabrik::System::Process' => [ ],
      },
   };
}

sub sig_int {
   my $self = shift;
   my ($master_pid) = @_;

   my $restore = $SIG{INT};

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("sig_int: INT caught");

      my $kernel = $self->_poe_kernel;

      my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
      $sp->kill($master_pid) or return;

      $kernel->stop;

      $SIG{INT} = $restore;
      return 1;
   };

   return 1;
}

sub _read {
   my $sock = shift;

   my $buf = '';
   my $chunk = 512;
   my $len = 0;
   my @ready = ();
   while (1) {
      my $n = $sock->sysread(my $tmp = '', $chunk);
      if (! defined($n)) {
         #print STDERR "undef: $!\n";
         last;
      }
      #print STDERR "read[$n]\n";
      if ($n == 0) {
         print STDERR "*** read eof\n";
         return;
         last;
      }
      $buf .= $tmp;
      $len += length($tmp);
   }
   if (@ready == 0) {
      #print STDERR "timeout\n";
   }

   return $buf;
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

   while (1) {
      if (my $ready = $st->wait_readable) {
         for my $sock (@$ready) {
            if ($sock == $server) {
               my $client = $st->accept;

               my $tunnel = $so->open_tunnel($remote_hostname, $remote_port) or return;
               $select->add($tunnel);
               $client->{tunnel} = $tunnel;

               $self->log->verbose("start: new connection from [".
                  $client->{ipv4}."]:".$client->{port});
            }
            else {
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
               if ($sock == $this_client) { # Client sent something
                  my $buf = $st->read($this_client);
                  if (! defined($buf)) {
                     #$self->log->verbose("start: client sent eof");
                     $select->remove($this_tunnel);
                     close($this_tunnel);
                     #$st->client_disconnected($client);
                  }
                  else {
                     $self->log->verbose("start: read from client [".length($buf)."]");
                     $this_tunnel->syswrite($buf);
                  }
               }
               elsif ($sock == $this_tunnel) {
                  my $buf = $st->read($this_tunnel);
                  if (! defined($buf)) {
                     #$self->log->verbose("start: tunnel sent eof");
                     $select->remove($this_tunnel);
                     close($this_tunnel);
                     #$st->client_disconnected($client);
                  }
                  else {
                     $self->log->verbose("start: read from tunnel [".length($buf)."]");
                     $this_client->syswrite($buf);
                  }
               }
            }
         }
      }
   }

   return 1;
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

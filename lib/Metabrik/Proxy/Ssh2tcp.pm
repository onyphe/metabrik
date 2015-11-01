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
         'Net::OpenSSH' => [ ],
         'POE::Kernel' => [ ],
         'POE::Component::Server::TCP' => [ ],
         'Metabrik::Network::Address' => [ ],
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

   my $ssh2 = Net::OpenSSH->new("$ssh_hostname:$ssh_port") or die("new");
   my $master_pid = $ssh2->get_master_pid;

   use POE qw(Component::Server::TCP);
   use POE qw(Wheel::ReadWrite);

   POE::Component::Server::TCP->new(
      Port => $port,
      Address => $hostname,
      ClientConnected => sub {
         my $heap = $_[HEAP];
         my $client = $heap->{client};

         $self->log->verbose("start: connection from [".$heap->{remote_ip}."]:".$heap->{remote_port});

         $self->sig_int($master_pid); # We have to reharm the signal

         my $socket = $client->[POE::Wheel::ReadWrite::HANDLE_INPUT()];
         $socket->autoflush(1);

         my ($tunnel, $pid) = $ssh2->open_tunnel({}, $remote_hostname, $remote_port)
            or die("open_tunnel");
         $tunnel->blocking(0);
         $tunnel->autoflush(1);

         $heap->{tunnel_pid} = $pid;

         $self->log->verbose("channel opened [$pid] tunnel[$tunnel]");

         my $select = IO::Select->new;
         $select->add($socket);
         $select->add($tunnel);

         my $stop = 0;
         while (1) {
            my @ready = ();
            while (@ready = $select->can_read(1)) {
               for my $this (@ready) {
                  if ($this == $socket) { # Client sent something
                     my $buf = _read($socket);
                     if (! defined($buf)) {
                        print STDERR "*** socket eof\n";
                        $stop++;
                        last;
                     }
                     $tunnel->syswrite($buf);
                  }
                  elsif ($this == $tunnel) {
                     my $buf = _read($tunnel);
                     if (! defined($buf)) {
                        print STDERR "*** tunnel eof\n";
                        $stop++;
                        last;
                     }
                     $socket->syswrite($buf);
                  }
               }
               last if $stop;
            }
            last if $stop;
         }
      },
      ClientFilter => "POE::Filter::Stream",
      ClientInput => sub {},  # Completely disabled, we do our own eventloop
      ClientDisconnected => sub {
         my $heap = $_[HEAP];
         my $kernel = $_[KERNEL];

         $self->log->verbose("start: disconnection from [".$heap->{remote_ip}."]:".$heap->{remote_port});

         my $pid = $heap->{tunnel_pid};

         my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
         $self->log->verbose("start: ClientDisconnected: killing pid[$pid]");
         $sp->kill($pid) or return;

         $self->sig_int($master_pid); # We have to reharm the signal
      }
   );

   $self->log->error("start: starting server on [$hostname]:$port");

   my $kernel = POE::Kernel->new;
   $self->_poe_kernel($kernel);

   #$self->sig_int;
   $self->_poe_kernel->run;

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

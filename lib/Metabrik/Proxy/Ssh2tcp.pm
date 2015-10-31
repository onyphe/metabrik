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
   $self->connect($ssh_hostname, $ssh_port) or return;

   my $ssh2 = $self->ssh2;

   use POE qw(Component::Server::TCP);

   POE::Component::Server::TCP->new(
      Port => $port,
      Address => $hostname,
      ClientConnected => sub {
         my $heap = $_[HEAP];
         $self->log->verbose("start: connection from [".$heap->{remote_ip}."]:".$heap->{remote_port});
         $self->sig_int; # We have to reharm the signal

         my $chan = $self->ssh2->tcpip($remote_hostname, $remote_port);
         if (! defined($chan)) {
            return $self->log->error("start: ClientConnected: unable to create channel to [$remote_hostname]:$remote_port");
         }
         #$chan->blocking(0);
         $heap->{chan} = $chan;
      },
      ClientFilter => "POE::Filter::Stream",
      ClientInput => sub {
         my $input = $_[ARG0];
         my $heap = $_[HEAP];
         my $client = $heap->{client};
         my $chan = $heap->{chan};

         $self->sig_int; # We have to reharm the signal

         print STDERR "> client to proxy len[".length($input)."]\n";
         print STDERR "> proxy to server len[".length($input)."]\n";
         $chan->write($input);

         #my $chunk = 2048;

         #my $r;
         #my $len = 0;
         #my $chunk = 1;
         #my $buf = '';
         #my @poll = ({handle => $chan, events => 'in'});
         #if ($ssh2->poll(250, \@poll) && $poll[0]->{revents}->{in}) {
            #while (defined(my $n = $chan->read(my $tmp = '',512))) {
               #$buf .= $tmp;
               #$len += $n;
            #}
         #}

         my $buf = '';
         my $chunk = 1;
         my $len = 0;
         while (1) {
         AGAIN:
            my $n;
            my $tmp = '';
            eval {
               local $SIG{ALRM} = sub { die };
               alarm(1); # 2 seconds with nothing, we stop read
               $n = $chan->read($tmp, $chunk);
               alarm(0);
            };
            last if $@ || not defined $n;
            $buf .= $tmp;
            $len += $n;
         }

         print STDERR "< server to proxy len[$len]\n";

         print "> proxy to client len[$len]\n";
         $client->put($buf);
         $self->sig_int; # We have to reharm the signal
      },
      ClientDisconnected => sub {
         my $heap = $_[HEAP];
         $self->log->verbose("start: disconnection from [".$heap->{remote_ip}."]:".$heap->{remote_port});

         $self->sig_int; # We have to reharm the signal
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

Metabrik::Proxy::Ssh2tcp - proxy::ssh2tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

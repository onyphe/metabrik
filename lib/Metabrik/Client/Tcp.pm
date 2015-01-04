#
# $Id$
#
# client::tcp Brik
#
package Metabrik::Client::Tcp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable client tcp socket netcat) ],
      attributes => {
         host => [ qw(host) ],
         port => [ qw(port) ],
         protocol => [ qw(tcp) ],
         eof => [ qw(0|1) ],
         size => [ qw(size) ],
         rtimeout => [ qw(read_timeout) ],
         use_ipv6 => [ qw(0|1) ],
         _socket => [ qw(INTERNAL) ],
         _select => [ qw(INTERNAL) ],
      },
      attributes_default => {
         port => 'tcp',
         eof => 0,
         size => 1024,
         use_ipv6 => 0,
      },
      commands => {
         connect => [ ],
         read => [ qw(size) ],
         readall => [ ],
         write => [ qw($data) ],
         disconnect => [ ],
         is_connected => [ ],
         chomp => [ qw($data) ],
      },
      require_modules => {
         'IO::Socket::INET' => [ ],
         'IO::Socket::INET6' => [ ],
         'IO::Select' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         rtimeout => $self->global->rtimeout,
      },
   };
}

sub connect {
   my $self = shift;
   my ($host, $port) = @_;

   $host ||= $self->host;
   $port ||= $self->port;

   if (! defined($host)) {
      return $self->log->error($self->brik_help_set('host'));
   }
   if (! defined($port)) {
      return $self->log->error($self->brik_help_set('port'));
   }

   my $context = $self->context;

   my $mod = $self->use_ipv6 ? 'IO::Socket::INET6' : 'IO::Socket::INET';

   my $socket = $mod->new(
      PeerHost => $host,
      PeerPort => $port,
      Proto => $self->protocol,
      Timeout => $self->rtimeout,
      ReuseAddr => 1,
   );
   if (! defined($socket)) {
      return $self->log->error("connect: failed connecting to target [$host:$port]: $!");
   }
         
   $socket->blocking(0);
   $socket->autoflush(1);

   my $select = IO::Select->new or return $self->log->error("connect: IO::Select failed: $!");
   $select->add($socket);

   $self->_socket($socket);
   $self->_select($select);

   $self->log->verbose("connect: successfully connected to [$host:$port]");

   my $conn = {
      ip => $socket->peerhost,
      port => $socket->peerport,
      my_ip => $socket->sockhost,
      my_port => $socket->sockport,
   };

   return $conn;
}

sub disconnect {
   my $self = shift;

   if ($self->_socket) {
      $self->_socket->close;
      $self->_socket(undef);
      $self->_select(undef);
      $self->log->verbose("disconnect: successfully disconnected");
   }
   else {
      $self->log->verbose("disconnect: nothing to disconnect");
   }

   return 1;
}

sub is_connected {
   my $self = shift;

   if ($self->_socket && $self->_socket->connected) {
      return 1;
   }

   return 0;
}

sub write {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   if (! $self->is_connected) {
      return $self->log->error("write: not connected");
   }

   my $socket = $self->_socket;

   my $ret = $socket->syswrite($data, length($data));
   if (! $ret) {
      return $self->log->error("write: syswrite failed with error [$!]");
   }

   return $ret;
}

sub read {
   my $self = shift;
   my ($size) = @_;

   $size ||= $self->size;

   if (! $self->is_connected) {
      return $self->log->error("read: not connected");
   }

   my $socket = $self->_socket;
   my $select = $self->_select;

   my $read = 0;
   my $eof = 0;
   my $data = '';
   while (my @read = $select->can_read($self->rtimeout)) {
      my $ret = $socket->sysread($data, $size);
      if (! defined($ret)) {
         return $self->log->error("read: sysread failed with error [$!]");
      }
      elsif ($ret == 0) { # EOF
         $self->eof(1);
         $eof++;
         last;
      }
      elsif ($ret > 0) { # Read stuff
         $read++;
         last;
      }
      else {
         return $self->log->fatal("read: What?!?");
      }
   }

   if (! $eof && ! $read) {
      $self->log->debug("read: timeout occured");
      return 0;
   }

   return $data;
}

sub chomp {
   my $self = shift;
   my ($data) = @_;

   $data =~ s/\r\n$//;
   $data =~ s/\r$//;
   $data =~ s/\n$//;

   $data =~ s/\r/\\x0d/g;
   $data =~ s/\n/\\x0a/g;

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::Client::Tcp - client::tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id$
#
# network::ftp Brik
#
package Metabrik::Network::Ftp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network ftp) ],
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(port) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         recurse => [ qw(0|1) ],
         _ftp => [ qw(INTERNAL) ],
      },
      attributes_default => {
         port => 21,
         username => 'anonymous',
         password => 'nop@no.fr',
         recurse => 0,
      },
      commands => {
         open => [ ],
         cwd => [ qw(directory|OPTIONAL) ],
         pwd => [ ],
         ls => [ qw(directory|OPTIONAL) ],
         dir => [ qw(directory|OPTIONAL) ],
         binary => [ ],
         ascii => [ ],
         rmdir => [ qw(directory) ],
         mkdir => [ qw(directory) ],
         get => [ qw(remote_file local_file|OPTIONAL) ],
         close => [ ],
      },
      require_modules => {
         'Net::FTP' => [ ],
      },
   };
}

sub open {
   my $self = shift;

   my $hostname = $self->hostname;
   if (! defined($hostname)) {
      return $self->log->error($self->brik_help_set('hostname'));
   }

   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password;

   my $ftp = Net::FTP->new(
      $hostname,
      Port => $port,
      Debug => $self->debug,
   ) or return $self->log->error("open: Net::FTP failed with [$@]");

   $ftp->login($username, $password)
      or return $self->log->error("open: Net::FTP login failed with [".$ftp->message."]");

   return $self->_ftp($ftp);
}

sub cwd {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '';

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $r = $ftp->cwd($directory);

   return $r;
}

sub pwd {
   my $self = shift;

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $r = $ftp->pwd;

   return $r;
}

sub ls {
   my $self = shift;
   my ($directory) = @_;

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   $directory ||= $ftp->pwd;

   my $list = $ftp->ls($directory);

   return $list;
}

sub dir {
   my $self = shift;
   my ($directory) = @_;

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   $directory ||= $ftp->pwd;

   my $list = $ftp->dir($directory);

   return $list;
}

sub rmdir {
   my $self = shift;
   my ($directory) = @_;

   if (! defined($directory)) {
      return $self->log->error($self->brik_help_run('rmdir'));
   }

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $r = $ftp->rmdir($directory, $self->recurse);

   return $r;
}

sub mkdir {
   my $self = shift;
   my ($directory) = @_;

   if (! defined($directory)) {
      return $self->log->error($self->brik_help_run('mkdir'));
   }

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $r = $ftp->mkdir($directory, $self->recurse);

   return $r;
}

sub binary {
   my $self = shift;

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $r = $ftp->binary;

   return $r;
}

sub ascii {
   my $self = shift;

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $r = $ftp->ascii;

   return $r;
}

sub get {
   my $self = shift;
   my ($remote, $local) = @_;

   my $ftp = $self->_ftp;
   if (! defined($ftp)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if (! defined($remote)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   $local ||= $self->global->output;

   my $r = $ftp->get($remote, $local);

   return $r;
}

sub close {
   my $self = shift;

   if (defined($self->_ftp)) {
      $self->_ftp->quit;
      $self->_ftp(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Ftp - network::ftp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

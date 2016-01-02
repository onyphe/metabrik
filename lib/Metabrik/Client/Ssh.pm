#
# $Id$
#
# client::ssh Brik
#
package Metabrik::Client::Ssh;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(integer) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         publickey => [ qw(file) ],
         privatekey => [ qw(file) ],
         ssh2 => [ qw(Net::SSH2) ],
         use_publickey => [ qw(0|1) ],
         _channel => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => 'localhost',
         username => 'root',
         port => 22,
         use_publickey => 1,
      },
      commands => {
         install => [ ], # Inherited
         connect => [ qw(hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         cat => [ qw(file) ],
         execute => [ qw(command) ],
         read => [ ],
         read_line => [ ],
         read_line_all => [ ],
         load => [ qw(file) ],
         listfiles => [ qw(glob) ],
         disconnect => [ ],
      },
      require_modules => {
         'IO::Scalar' => [ ],
         'Net::SSH2' => [ ],
         'Metabrik::String::Password' => [ ],
      },
      need_packages => {
         'ubuntu' => [ qw(libssh2-1-dev) ],
      },
   };
}

sub connect {
   my $self = shift;
   my ($hostname, $port, $username, $password) = @_;

   if (defined($self->ssh2)) {
      return $self->log->verbose("connect: already connected");
   }

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('connect', $hostname) or return;
   $self->brik_help_run_undef_arg('connect', $port) or return;
   $self->brik_help_run_undef_arg('connect', $username) or return;

   my $publickey = $self->publickey;
   my $privatekey = $self->privatekey;
   if ($self->use_publickey && ! $publickey) {
      return $self->log->error($self->brik_help_set('publickey'));
   }
   if ($self->use_publickey && ! $privatekey) {
      return $self->log->error($self->brik_help_set('privatekey'));
   }

   my $ssh2 = Net::SSH2->new;
   if (! defined($ssh2)) {
      return $self->log->error("connect: cannot create Net::SSH2 object");
   }

   my $ret = $ssh2->connect($hostname, $port);
   if (! $ret) {
      return $self->log->error("connect: can't connect via SSH2: $!");
   }

   if ($self->use_publickey) {
      $ret = $ssh2->auth(
         username => $username,
         publickey => $publickey,
         privatekey => $privatekey,
      );
      if (! $ret) {
         return $self->log->error("connect: authentication failed with publickey: $!");
      }
   }
   else {
      # Prompt for password if not given
      if (! defined($password)) {
         my $sp = Metabrik::String::Password->new_from_brik_init($self) or return;
         $password = $sp->prompt;
      }

      $ret = $ssh2->auth_password($username, $password);
      if (! $ret) {
         return $self->log->error("connect: authentication failed with password: $!");
      }
   }

   $self->log->verbose("connect: ssh2 connected to [$hostname]:$port");

   return $self->ssh2($ssh2);
}

sub disconnect {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->verbose("disconnect: not connected");
   }

   my $r = $ssh2->disconnect;

   $self->ssh2(undef);
   $self->_channel(undef);

   return $r;
}

sub execute {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('execute', $cmd) or return;

   $self->debug && $self->log->debug("execute: cmd [$cmd]");

   my $channel = $ssh2->channel;
   if (! defined($channel)) {
      return $self->log->error("execute: channel creation error");
   }

   $channel->exec($cmd)
      or return $self->log->error("execute: can't execute command [$cmd]: $!");

   return $self->_channel($channel);
}

sub read_line {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->info("read_line: create a channel first");
   }

   my $read = '';
   my $count = 1;
   while (1) {
      my $char = '';
      my $rc = $channel->read($char, $count);
      if ($rc > 0) {
         #print "read[$char]\n";
         #print "returned[$c]\n";
         $read .= $char;

         last if $char eq "\n";
      }
      elsif ($rc < 0) {
         return $self->log->error("read_line: error [$rc]");
      }
      else {
         last;
      }
   }

   return $read;
}

sub read_line_all {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->info("read_line_all: create a channel first");
   }

   my $read = $self->read;
   if (! defined($read)) {
      return $self->log->error("read_line_all: read error");
   }

   my @lines = split(/\n/, $read);

   return \@lines;
}

sub read {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->info("read: create a channel first");
   }

   my $read = '';
   my $count = 1024;
   while (1) {
      my $buf = '';
      my $rc = $channel->read($buf, $count);
      if ($rc > 0) {
         #print "read[$buf]\n";
         #print "returned[$c]\n";
         $read .= $buf;

         last if $rc < $count;
      }
      elsif ($rc < 0) {
         return $self->log->error("read: error [$rc]");
      }
      else {
         last;
      }
   }

   return $read;
}

sub listfiles {
   my $self = shift;
   my ($glob) = @_;

   my $channel = $self->execute("ls $glob 2> /dev/null") or return;

   my $read = $self->read;
   if (! defined($read)) {
      return $self->log->error("listfiles: read error");
   }

   my @files = split(/\n/, $read);

   return \@files;
}

sub cat {
   my $self = shift;
   my ($file) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('cat', $file) or return;

   my $channel = $self->execute('cat '.$file) or return;

   return $self->_channel($channel);
}

sub load {
   my $self = shift;
   my ($file) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('load', $file) or return;

   my $io = IO::Scalar->new;

   $ssh2->scp_get($file, $io)
      or return $self->log->error("load: scp_get: $file");

   $io->seek(0, 0);

   my $buf = '';
   while (<$io>) {
      $buf .= $_;
   }

   return $buf;
}

sub brik_fini {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (defined($ssh2)) {
      $ssh2->disconnect;
      $self->ssh2(undef);
      $self->_channel(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Ssh - client::ssh Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

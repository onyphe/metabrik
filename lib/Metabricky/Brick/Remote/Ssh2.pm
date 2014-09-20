#
# $Id: Ssh2.pm 89 2014-09-17 20:29:29Z gomor $
#
# Ssh2 brick
#
package Metabricky::Brick::Remote::Ssh2;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   host
   port
   username
   publickey
   privatekey
   ssh2
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Net::SSH2',
   ];
}

sub help {
   return [
      'set remote::ssh2 host <ip|hostname>',
      'set remote::ssh2 port <port>',
      'set remote::ssh2 username <user>',
      'set remote::ssh2 publickey <file>',
      'set remote::ssh2 privatekey <file>',
      'run remote::ssh2 connect',
      'run remote::ssh2 cat <file>',
      'run remote::ssh2 cmd <command>',
      'run remote::ssh2 readline',
      'run remote::ssh2 listfiles <glob>',
      'run remote::ssh2 disconnect',
   ];
}

sub default_values {
   return {
      host => 'localhost',
      port => 22,
      username => 'root',
   };
}

sub connect {
   my $self = shift;

   if (defined($self->ssh2)) {
      return $self->log->verbose("connect: already connected");
   }

   if (! defined($self->host)) {
      return $self->log->info("set remote::ssh2 host <ip|hostname>");
   }

   if (! defined($self->port)) {
      return $self->log->info("set remote::ssh2 port <port>");
   }

   if (! defined($self->username)) {
      return $self->log->info("set remote::ssh2 username <user>");
   }

   if (! defined($self->publickey)) {
      return $self->log->info("set remote::ssh2 publickey <file>");
   }

   if (! defined($self->privatekey)) {
      return $self->log->info("set remote::ssh2 privatekey <file>");
   }

   my $ssh2 = Net::SSH2->new;
   my $ret = $ssh2->connect($self->host, $self->port);
   if (! $ret) {
      return $self->log->error("connect: can't connect via SSH2: $!");
   }

   $ret = $ssh2->auth(
      username => $self->username,
      publickey => $self->publickey,
      privatekey => $self->privatekey,
   );
   if (! $ret) {
      return $self->log->error("connect: can't authenticate via SSH2: $!");
   }

   $self->log->verbose("connect: ssh2 connected to [".$self->host."]");

   return $self->ssh2($ssh2);
}

sub disconnect {
   my $self = shift;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      return $self->log->info("run remote::ssh2 connect");
   }

   my $r = $ssh2->disconnect;

   $self->ssh2(undef);

   return $r;
}

sub cmd {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      return $self->log->info("run remote::ssh2 connect");
   }

   if (! defined($cmd)) {
      return $self->log->info("run remote::ssh2 cmd <cmd>");
   }

   $self->debug && $self->log->debug("cmd: cmd [$cmd]");

   my $chan = $ssh2->channel;
   if (! defined($chan)) {
      return $self->log->error("cmd: channel creation error");
   }

   $chan->exec($cmd)
      or return $self->log->error("cmd: can't execute command [$cmd]: $!");

   return $chan;
}

sub readline {
   my $self = shift;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      return $self->log->info("run remote::ssh2 connect");
   }

   my $channel = $ssh2->channel;
   if (! defined($channel)) {
      return $self->log->error("readline: channel creation error");
   }

   my @lines = ();
   while (! $channel->eof) {
      if (defined(my $line = <$channel>)) {
         chomp($line);
         push @lines, $line;
         # We only want one line
         last;
      }
   }

   return \@lines;
}

sub readall {
   my $self = shift;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      return $self->log->info("run remote::ssh2 connect");
   }

   my $channel = $ssh2->channel;
   if (! defined($channel)) {
      return $self->log->error("readall: channel creation error");
   }

   my @lines = ();
   while (! $channel->eof) {
      if (defined(my $line = <$channel>)) {
         chomp($line);
         push @lines, $line;
      }
   }

   return \@lines;
}

sub listfiles {
   my $self = shift;
   my ($glob) = @_;

   my $channel = $self->cmd("ls $glob 2> /dev/null");
   if (! defined($channel)) {
      return $self->log->error("listfiles: cmd error");
   }

   my $all = $self->readall;
   if (! defined($all)) {
      return $self->log->error("listfiles: readall error");
   }

   return $all;
}

sub cat {
   my $self = shift;
   my ($file) = @_;

   if (! defined($file)) {
      return $self->log->info("run remote::ssh2 cat <file>");
   }

   return $self->cmd('cat '.$file);
}

sub DESTROY {
   my $self = shift;

   $self->debug && $self->log->debug("DESTROY: called");

   my $ssh2 = $self->ssh2;
   if (defined($ssh2)) {
      $ssh2->disconnect;
      $self->ssh2(undef);
   }

   return 1;
}

1;

__END__

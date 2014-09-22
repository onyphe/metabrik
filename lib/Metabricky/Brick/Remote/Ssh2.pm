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
   hostname
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
   return {
      'set:hostname' => '<ip|hostname>',
      'set:port' => '<port>',
      'set:username' => '<user>',
      'set:publickey' => '<file>',
      'set:privatekey' => '<file>',
      'run:connect' => '',
      'run:cat' => '<file>',
      'run:exec' => '<command>',
      'run:readall' => '<channel>',
      'run:readline' => '<channel>',
      'run:listfiles' => '<glob>',
      'run:disconnect' => '',
   };
}

sub default_values {
   my $self = shift;

   return {
      hostname => $self->bricks->{'core::global'}->hostname || 'localhost',
      port => 22,
      username => $self->bricks->{'core::global'}->username || 'root',
   };
}

sub connect {
   my $self = shift;

   if (defined($self->ssh2)) {
      return $self->log->verbose("connect: already connected");
   }

   if (! defined($self->hostname)) {
      return $self->log->info($self->help_set('hostname'));
   }

   if (! defined($self->port)) {
      return $self->log->info($self->help_set('port'));
   }

   if (! defined($self->username)) {
      return $self->log->info($self->help_set('username'));
   }

   if (! defined($self->publickey)) {
      return $self->log->info($self->help_set('publickey'));
   }

   if (! defined($self->privatekey)) {
      return $self->log->info($self->help_set('privatekey'));
   }

   my $ssh2 = Net::SSH2->new;
   my $ret = $ssh2->connect($self->hostname, $self->port);
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

   $self->log->verbose("connect: ssh2 connected to [".$self->hostname."]");

   return $self->ssh2($ssh2);
}

sub disconnect {
   my $self = shift;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   my $r = $ssh2->disconnect;

   $self->ssh2(undef);

   return $r;
}

sub exec {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   if (! defined($cmd)) {
      return $self->log->info($self->help_run('exec'));
   }

   $self->debug && $self->log->debug("exec: cmd [$cmd]");

   my $chan = $ssh2->channel;
   if (! defined($chan)) {
      return $self->log->error("exec: channel creation error");
   }

   $chan->exec($cmd)
      or return $self->log->error("exec: can't execute command [$cmd]: $!");

   return $chan;
}

sub readline {
   my $self = shift;
   my ($channel) = @_;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   if (! defined($channel)) {
      return $self->log->info($self->help_run('readline'));
   }

   my @lines = ();
   while (! $channel->eof) {
      while (defined(my $line = <$channel>)) {
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
   my ($channel) = @_;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   if (! defined($channel)) {
      return $self->log->info($self->help_run('readall'));
   }

   my @lines = ();
   while (! $channel->eof) {
      while (defined(my $line = <$channel>)) {
         chomp($line);
         push @lines, $line;
      }
   }

   return \@lines;
}

sub listfiles {
   my $self = shift;
   my ($glob) = @_;

   my $channel = $self->exec("ls $glob 2> /dev/null");
   if (! defined($channel)) {
      return $self->log->error("listfiles: exec error");
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
      return $self->log->info($self->run_help('cat'));
   }

   return $self->exec('cat '.$file);
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

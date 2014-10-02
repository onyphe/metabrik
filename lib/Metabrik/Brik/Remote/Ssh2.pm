#
# $Id$
#
# remote::ssh2 Brik
#
package Metabrik::Brik::Remote::Ssh2;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      hostname => [],
      port => [],
      username => [],
      publickey => [],
      privatekey => [],
      ssh2 => [],
      _channel => [],
   };
}

sub require_modules {
   return {
      'IO::Scalar' => [],
      'Net::SSH2' => [],
   };
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
      'run:readall' => '',
      'run:readline' => '',
      'run:readlineall' => '',
      'run:load' => '<file>',
      'run:listfiles' => '<glob>',
      'run:disconnect' => '',
   };
}

sub default_values {
   my $self = shift;

   return {
      hostname => $self->global->hostname || 'localhost',
      port => 22,
      username => $self->global->username || 'root',
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
   $self->_channel(undef);

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

   my $channel = $ssh2->channel;
   if (! defined($channel)) {
      return $self->log->error("exec: channel creation error");
   }

   $channel->exec($cmd)
      or return $self->log->error("exec: can't execute command [$cmd]: $!");

   return $self->_channel($channel);
}

sub readline {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->info("readline: create a channel first");
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
         return $self->log->error("read: error [$rc]");
      }
      else {
         last;
      }
   }

   return $read;
}

sub readlineall {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->info("readlineall: create a channel first");
   }

   my $read = $self->readall;
   if (! defined($read)) {
      return $self->log->error("readlineall: readall error");
   }

   my @lines = split(/\n/, $read);

   return \@lines;
}

sub readall {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->info("readall: create a channel first");
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

   my $channel = $self->exec("ls $glob 2> /dev/null");
   if (! defined($channel)) {
      return $self->log->error("listfiles: exec error");
   }

   my $read = $self->readall;
   if (! defined($read)) {
      return $self->log->error("listfiles: readall error");
   }

   my @files = split(/\n/, $read);

   return \@files;
}

sub cat {
   my $self = shift;
   my ($file) = @_;

   if (! defined($self->ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   if (! defined($file)) {
      return $self->log->info($self->help_run('cat'));
   }

   my $channel = $self->exec('cat '.$file);
   if (! defined($channel)) {
      return $self->log->error("cat: channel for file [$file]");
   }

   return $self->_channel($channel);
}

sub load {
   my $self = shift;
   my ($file) = @_;

   if (! defined($self->ssh2)) {
      return $self->log->info($self->help_run('connect'));
   }

   if (! defined($file)) {
      return $self->log->info($self->help_run('load'));
   }

   my $ssh2 = $self->ssh2;

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

sub DESTROY {
   my $self = shift;

   $self->debug && $self->log->debug("DESTROY: called");

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

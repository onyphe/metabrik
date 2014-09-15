#
# $Id$
#
# Ssh2 brick
#
package Metabricky::Brick::Remote::Ssh2;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   host
   username
   publickey
   privatekey
   ssh2
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SSH2;

sub help {
   print "set remote::ssh2 host <ip|hostname>\n";
   print "set remote::ssh2 username <user>\n";
   print "set remote::ssh2 publickey <file>\n";
   print "set remote::ssh2 privatekey <file>\n";
   print "\n";
   print "run remote::ssh2 connect\n";
   print "run remote::ssh2 cat <file>\n";
   print "run remote::ssh2 cmd <command>\n";
   print "run remote::ssh2 listfiles <glob>\n";
   print "run remote::ssh2 disconnect\n";
}

sub require_set_connect { qw(host username publickey privatekey) }
sub require_arg_connect { qw() }
sub require_cmd_connect { qw() }

sub connect {
   my $self = shift;

   if (defined($self->ssh2)) {
      die("we are already connected\n");
   }

   if (! defined($self->host)
   ||  ! defined($self->username)
   ||  ! defined($self->publickey)
   ||  ! defined($self->privatekey)) {
      return $self->require_attributes(qw(host username publickey privatekey));
   }

   my $ssh2 = Net::SSH2->new;
   my $ret = $ssh2->connect($self->host);
   if (! $ret) {
      die("can't connect via SSH2: $!\n");
   }

   $ret = $ssh2->auth(
      username => $self->username,
      publickey => $self->publickey,
      privatekey => $self->privatekey,
   );
   if (! $ret) {
      die("can't authenticate via SSH2: $!\n");
   }

   if ($self->debug) {
      print "DEBUG: ssh2 connected to [".$self->host."]\n";
   }

   return $self->ssh2($ssh2);
}

sub require_set_disconnect { qw() }
sub require_arg_disconnect { qw() }
sub require_cmd_disconnect { qw(connect) }

sub disconnect {
   my $self = shift;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      die("run remote::ssh2 connect\n");
   }

   my $r = $ssh2->disconnect;

   $self->ssh2(undef);

   return $r;
}

sub require_set_cmd { qw() }
sub require_arg_cmd { qw(command) }
sub require_cmd_cmd { qw(connect) }

sub cmd {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = $self->ssh2;

   if (! defined($ssh2)) {
      die("run remote::ssh2 connect\n");
   }

   if (! defined($cmd)) {
      die("run remote::ssh2 cmd <cmd>\n");
   }

   print "DEBUG: cmd[$cmd]\n" if $self->debug;

   my $chan = $ssh2->channel;
   $chan->exec($cmd) or die("can't execute command [$cmd]: $!\n");

   #my @lines = <$chan>;
   #print "@lines\n";

   return $chan;
}

sub listfiles {
   my $self = shift;
   my ($glob) = @_;

   my $chan = $self->cmd("ls $glob 2> /dev/null");

   my @files = ();
   my @lines = <$chan>;
   if (@lines > 0) {
      for my $l (@lines) {
         chomp($l);
         #print "DEBUG file[$l]\n";
         push @files, $l;
      }
   }

   return \@files;
}

sub test {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = Net::SSH2->new;
   my $ret = $ssh2->connect($self->host);
   if (! $ret) {
      die("can't connect via SSH2: $!\n");
   }

   $ret = $ssh2->auth(
      username => $self->username,
      publickey => $self->publickey,
      privatekey => $self->privatekey,
   );
   if (! $ret) {
      die("can't authenticate via SSH2: $!\n");
   }

   if ($self->debug) {
      print "DEBUG: ssh2 connected to [".$self->host."]\n";
   }

   my $chan = $ssh2->channel or die("channel: $!");
   $chan->exec($cmd) or die("can't execute command [$cmd]: $!\n");

   #my $line = <$chan>;
   #print "$line\n";

   return $chan;
}

sub require_set_cat { qw() }
sub require_arg_cat { qw(file) }
sub require_cmd_cat { qw(connect) }

sub cat {
   my $self = shift;
   my ($file) = @_;

   if (! defined($file)) {
      die("you must provide a file as an argument to 'run remote::ssh2 cat'\n");
   }

   return $self->cmd('cat '.$file);
}

sub DESTROY {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (defined($ssh2)) {
      $ssh2->disconnect;
      $self->ssh2(undef);
   }

   return 1;
}

1;

__END__

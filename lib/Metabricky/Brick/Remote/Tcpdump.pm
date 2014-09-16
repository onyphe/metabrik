#
# $Id$
#
# remote::tcpdump brick
#
package Metabricky::Brick::Remote::Tcpdump;
use strict;
use warnings;

use base qw(Metabricky::Brick::Remote::Ssh2);

our @AS = qw(
   _started
   _channel
   _out
   _dump
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Dump::Offline;

sub help {
   print "set remote::tcpdump host <ip|hostname>\n";
   print "set remote::tcpdump username <user>\n";
   print "set remote::tcpdump publickey <file>\n";
   print "set remote::tcpdump privatekey <file>\n";
   print "\n";
   print "run remote::tcpdump start\n";
   print "run remote::tcpdump status\n";
   print "run remote::tcpdump stop\n";
   print "run remote::tcpdump next\n";
   print "run remote::tcpdump nextall\n";
}

sub default_values {
   return {
      _started => 0,
      _channel => undef,
      username => 'root',
      host => 'localhost',
   };
}

sub start {
   my $self = shift;

   if ($self->_started) {
      return $self->log->verbose("already start");
   }

   $self->connect or return;
   if ($self->debug) {
      $self->log->info("ssh connection successful");
   }

   my $dump = Net::Frame::Dump::Offline->new;
   $self->_dump($dump);

   $self->log->debug("dump file[".$dump->file."]");

   open(my $out, '>', $dump->file)
      or return $self->log->error("cannot open file: $!");
   my $old = select($out);
   $|++;
   select($old);
   $self->_out($out);

   my $channel = $self->cmd("tcpdump -U -w - 2> /dev/null") or return;
   if ($self->debug) {
      $self->log->info("tcpdump started");
   }

   $self->_started(1);

   return $self->_channel($channel);
}

sub status {
   my $self = shift;

   return $self->_started;
}

sub stop {
   my $self = shift;

   if (! $self->_started) {
      return $self->log->verbose("run remote::tcpdump start");
   }

   $self->nextall;

   my $r = $self->disconnect;
   $self->_dump->stop;
   unlink($self->_dump->file);
   close($self->_out);

   $self->_started(0);
   $self->_channel(undef);
   $self->_out(undef);
   $self->_dump(undef);

   return $r;
}

sub next {
   my $self = shift;

   if (! $self->_started) {
      return $self->log->verbose("run remote::tcpdump start");
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->error("channel not found");
   }

   my $out = $self->_out;
   while (my $line = <$channel>) {
      print $out $line;
   }

   # If reader not already open, we open it
   my $dump = $self->_dump;
   if (! $dump->isRunning) {
      $dump->start or return $self->log->error("unable to start pcap reader");
   }

   if (my $h = $dump->next) {
      return $h;
   }

   return;
}

sub nextall {
   my $self = shift;

   if (! $self->_started) {
      return $self->log->verbose("run remote::tcpdump start");
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->error("channel not found");
   }

   my $out = $self->_out;
   while (my $line = <$channel>) {
      print $out $line;
   }

   # If reader not already open, we open it
   my $dump = $self->_dump;
   if (! $dump->isRunning) {
      $dump->start or return $self->log->error("unable to start pcap reader");
   }

   my @next = ();
   while (my $h = $dump->next) {
      push @next, $h;
   }

   return \@next;
}

1;

__END__

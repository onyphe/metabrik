#
# $Id$
#
# Net::Netmask plugin
#
package Plashy::Plugin::Netmask;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   subnet
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Netmask;

sub help {
   print "set netmask subnet <subnet>\n";
   print "\n";
   print "run netmask match <ip>\n";
   print "run netmask first\n";
   print "run netmask last\n";
   print "run netmask block\n";
   print "run netmask iplist\n";
}

sub match {
   my $self = shift;
   my ($ip) = @_;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   if ($block->match($ip)) {
      print "$ip is in the same subnet as $subnet\n";
   }
   else {
      print "$ip is NOT in the same subnet as $subnet\n";
   }

   return 1;
}

sub block {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   return $block;
}

sub iplist {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   return $block->enumerate;
}

sub first {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   print $block->first."\n";

   return 1;
}

sub last {
   my $self = shift;

   my $subnet = $self->subnet or return;
   my $block = Net::Netmask->new($subnet);

   print $block->last."\n"; 

   return 1;
}

1;

__END__

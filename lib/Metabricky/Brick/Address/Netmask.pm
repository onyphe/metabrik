#
# $Id$
#
# Net::Netmask brick
#
package Metabricky::Brick::Address::Netmask;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   subnet
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Netmask;

sub help {
   print "set address::netmask subnet <subnet>\n";
   print "\n";
   print "run address::netmask match <ip>\n";
   print "run address::netmask first\n";
   print "run address::netmask last\n";
   print "run address::netmask block\n";
   print "run address::netmask iplist\n";
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

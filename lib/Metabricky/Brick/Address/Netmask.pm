#
# $Id: Netmask.pm 89 2014-09-17 20:29:29Z gomor $
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
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Net::Netmask',
   ];
}

sub help {
   return [
      'set address::netmask subnet <subnet>',
      'run address::netmask match <ip>',
      'run address::netmask first',
      'run address::netmask last',
      'run address::netmask block',
      'run address::netmask iplist',
   ];
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

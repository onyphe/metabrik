#
# $Id$
#
# address::netmask Brick
#
package Metabricky::Brick::Address::Netmask;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub declare_attributes {
   return {
      subnet => [],
   };
}

sub default_values {
   return {
      subnet => '192.168.0.0/24',
   };
}

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'Net::Netmask' => [],
   };
}

sub help {
   return {
      'set:subnet' => '<subnet>',
      'run:match' => '<ip> - tells if given IP address is within subnet',
      'run:first' => '',
      'run:last' => '',
      'run:block' => '',
      'run:iplist' => '',
   };
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

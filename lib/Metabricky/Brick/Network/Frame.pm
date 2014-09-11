#
# $Id$
#
# Net::Frame modules brick
#
package Metabricky::Brick::Network::Frame;
use strict;
use warnings;

use base qw(Metabricky::Brick);

#our @AS = qw(
#);
__PACKAGE__->cgBuildIndices;
#__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame;
use Net::Frame::Device;
use Net::Frame::Layer::ETH;
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::IPv6;
use Net::Frame::Layer::TCP;
use Net::Frame::Layer::UDP;
use Net::Frame::Layer::ICMPv4;
use Net::Frame::Layer::ICMPv6;

sub help {
   print "set network::frame device <interface>\n";
   print "\n";
   #print "run core::template command2 <argument1> <argument2>\n";
}

sub command1 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      die($self->help);
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub command2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      die($self->help);
   }

   my $do_something = "you should do something";

   return $do_something;
}

1;

__END__

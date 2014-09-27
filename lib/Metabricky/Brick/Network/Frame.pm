#
# $Id: Frame.pm 89 2014-09-17 20:29:29Z gomor $
#
# Net::Frame modules brick
#
package Metabricky::Brick::Network::Frame;
use strict;
use warnings;

use base qw(Metabricky::Brick);

# XXX: TODO

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'Net::Frame' => [],
      'Net::Frame::Device' => [],
      'Net::Frame::Layer::ETH' => [],
      'Net::Frame::Layer::IPv4' => [],
      'Net::Frame::Layer::IPv6' => [],
      'Net::Frame::Layer::TCP' => [],
      'Net::Frame::Layer::UDP' => [],
      'Net::Frame::Layer::ICMPv4' => [],
      'Net::Frame::Layer::ICMPv6' => [],
   };
}

sub help {
   return {
      'set:device' => '<device>',
   };
}

sub command1 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      return $self->log->info("command1");
   }

   my $do_something = "you should do something";

   return $do_something;
}

sub command2 {
   my $self = shift;
   my ($argument1, $argument2) = @_;

   if (! defined($argument2)) {
      return $self->log->info("command2");
   }

   my $do_something = "you should do something";

   return $do_something;
}

1;

__END__

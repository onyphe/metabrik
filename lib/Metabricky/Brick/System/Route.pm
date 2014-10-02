#
# $Id$
#
# system::route Brick
#
package Metabricky::Brick::System::Route;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      dnet => [],
   };
}

sub require_modules {
   return {
      'Net::Libdnet::Route' => [],
   };
}

sub help {
   return {
      'run:show' => '',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $dnet = Net::Libdnet::Route->new
      or return $self->log->error("can't create Net::Libdnet::Route object");

   $self->dnet($dnet);

   return $self;
}

sub _display {
   my ($entry, $data) = @_;

   my $buf = sprintf("%-30s %-30s", $entry->{route_dst}, $entry->{route_gw});
   print "$buf\n";

   return $buf;
}

sub show {
   my $self = shift;

   printf("%-30s %-30s\n", 'Destination', 'Gateway');
   my $data = '';
   $self->dnet->loop(\&_display, \$data);

   return 1;
}

1;

__END__

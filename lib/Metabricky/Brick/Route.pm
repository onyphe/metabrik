#
# $Id$
#
# Route brick
#
package Metabricky::Brick::Route;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   dnet
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet::Route;

sub help {
   print "run route show\n";
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $dnet = Net::Libdnet::Route->new or die("init");
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

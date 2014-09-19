#
# $Id: Route.pm 89 2014-09-17 20:29:29Z gomor $
#
# Route brick
#
package Metabricky::Brick::System::Route;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   dnet
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Net::Libdnet::Route',
   ];
}

sub help {
   return [
      'run system::route show',
   ];
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

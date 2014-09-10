#
# $Id$
#
# Arp brick
#
package MetaBricky::Brick::Arp;
use strict;
use warnings;

use base qw(MetaBricky::Brick);

our @AS = qw(
   dnet
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet::Arp;

sub help {
   print "run arp show\n";
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $dnet = Net::Libdnet::Arp->new or die("init");
   $self->dnet($dnet);

   return $self;
}

sub _display {
   my ($entry, $data) = @_;

   my $buf = sprintf("%-30s %-30s", $entry->{arp_pa}, $entry->{arp_ha});
   print "$buf\n";

   return $buf;
}

sub show {
   my $self = shift;

   printf("%-30s %-30s\n", 'IP address', 'MAC address');
   my $data = '';
   $self->dnet->loop(\&_display, \$data);

   return 1;
}

1;

__END__

#
# $Id$
#
# Arp brick
#
package Metabricky::Brick::System::Arp;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   _dnet
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet::Arp;

sub help {
   print "run system::arp cache\n";
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   my $dnet = Net::Libdnet::Arp->new;
   if (! defined($dnet)) {
      return $self->log->error("unable to create Net::Libdnet::Arp object");
   }

   $self->_dnet($dnet);

   return $self;
}

sub _loop {
   my ($entry, $data) = @_;

   $data->{ip}->{$entry->{arp_pa}} = $entry->{arp_ha};
   $data->{mac}->{$entry->{arp_ha}} = $entry->{arp_pa};

   return $data;
}

sub cache {
   my $self = shift;

   my %data = ();
   $self->_dnet->loop(\&_loop, \%data);

   return \%data;
}

1;

__END__

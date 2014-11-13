#
# $Id$
#
# system::arp brik
#
package Metabrik::System::Arp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable arp cache) ],
      attributes => {
         _dnet => [ qw(Net::Libdnet::Arp) ],
      },
      commands => {
         cache => [ ],
      },
      require_modules => {
         'Net::Libdnet::Arp' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
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

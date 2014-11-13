#
# $Id$
#
# database::vfeed Brik
#
package Metabrik::Database::Vfeed;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable cve vfeed) ],
      attributes => {
         db => [ qw(vfeed_db) ],
         vfeed => [ qw(vFeed::DB) ],
      },
      commands => {
         vfeed_version => [ ],
         update => [ ],
         cve => [ qw(cve_id) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'vFeed::DB' => [ ],
         'vFeed::Log' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   if (! defined($self->db)) {
      return $self->log->error($self->brik_help_set('db'));
   }

   my $log = vFeed::Log->new;
   my $vfeed = vFeed::DB->new(
      log => $log,
      file => $self->db,
   );

   $vfeed->init;

   $self->vfeed($vfeed);

   return $self;
}

sub vfeed_version {
   my $self = shift;

   my $version = $self->vfeed->db_version;
   print "vFeed version: $version\n";

   return $version;
}

sub cve {
   my $self = shift;
   my ($id) = @_;

   my $vfeed = $self->vfeed;

   my $cve = $vfeed->get_cve($id);
   print Dumper($cve),"\n";

   my $cpe = $vfeed->get_cpe($id);
   print Dumper($cpe),"\n";

   my $cwe = $vfeed->get_cwe($id);
   print Dumper($cwe),"\n";

   return {
      cve => $cve,
      cpe => $cpe,
      cwe => $cwe,
   };
}

sub update {
   my $self = shift;

   my $vfeed = $self->vfeed;

   $vfeed->update;

   return $self;
}

1;

__END__

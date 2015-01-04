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
   my $self = shift;

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

   return $self->SUPER::brik_init;
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

=head1 NAME

Metabrik::Database::Vfeed - database::vfeed Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

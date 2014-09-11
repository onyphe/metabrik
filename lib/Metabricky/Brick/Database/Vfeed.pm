#
# $Id$
#
# vFeed brick
#
package Metabricky::Brick::Vfeed;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   db
   vfeed
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Data::Dumper;

use vFeed::DB;
use vFeed::Log;

sub help {
   print "set vfeed db <sqlite>\n";
   print "\n";
   print "run vfeed version\n";
   print "run vfeed update\n";
   print "run vfeed cve <id>\n";
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   if (! defined($self->db)) {
      die("set vfeed db <sqlite>\n");
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

sub version {
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

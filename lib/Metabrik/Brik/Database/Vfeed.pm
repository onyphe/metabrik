#
# $Id$
#
# database::vfeed Brik
#
package Metabrik::Brik::Database::Vfeed;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      db => [],
      vfeed => [],
   };
}

sub require_modules {
   return {
      'Data::Dumper' => [],
      'vFeed::DB' => [],
      'vFeed::Log' => [],
   };
}

sub help {
   return {
      'set:db' => '<sqlite>',
      'run:version' => '',
      'run:update' => '',
      'run:cve' => '<id>',
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   if (! defined($self->db)) {
      return $self->log->info($self->help_set('db'));
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

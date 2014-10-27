#
# $Id$
#
# perl::module Brik
#
package Metabrik::Brik::Perl::Module;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(perl module install) ],
      commands => {
         install => [ qw(SCALAR) ],
      },
   };
}

sub install {
   my $self = shift;
   my ($module) = @_;

   if (! defined($module)) {
      return $self->log->info($self->brik_help_run('install'));
   }

   if ($module !~ /^[A-Za-z0-9:]+$/) {
      return $self->log->error("install: module [$module]: invalid format");
   }

   system("cpanm $module");

   $self->log->info('install: don\'t forget to add this line to your shell rc file:');
   $self->log->info('eval $(perl -I ~/perl5/lib/perl5 -Mlocal::lib)');

   return 1;
}

1;

__END__

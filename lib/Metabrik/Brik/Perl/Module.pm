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
      tags => [ qw(perl module install cpan) ],
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

   system("metabrik-cpanm $module");

   return 1;
}

1;

__END__

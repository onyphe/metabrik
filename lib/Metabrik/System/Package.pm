#
# $Id$
#
# system::package Brik
#
package Metabrik::System::Package;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(experimental package) ],
      commands => {
         search => [ qw(string) ],
         install => [ qw(package) ],
         update => [ ],
         upgrade => [ ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'aptitude' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   my $cmd = "aptitude search $package";

   return $self->context->run('shell::command', 'system', $cmd);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('install'));
   }

   my $cmd = "sudo apt-get install $package";

   return $self->context->run('shell::command', 'system', $cmd);
}

sub update {
   my $self = shift;

   my $cmd = "sudo apt-get update";

   return $self->context->run('shell::command', 'system', $cmd);
}

sub upgrade {
   my $self = shift;

   my $cmd = "sudo apt-get upgrade";

   return $self->context->run('shell::command', 'system', $cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Package - system::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

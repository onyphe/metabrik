#
# $Id$
#
# system::freebsd::package Brik
#
package Metabrik::System::Freebsd::Package;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         search => [ qw(string) ],
         install => [ qw(package) ],
         update => [ ],
         upgrade => [ ],
         list => [ ],
      },
      require_binaries => {
         'sudo' => [ ],
         'pkg' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('search'));
   }

   my $cmd = "pkg search $package";

   return $self->capture($cmd);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   if (! defined($package)) {
      return $self->log->error($self->brik_help_run('install'));
   }

   my $cmd = "sudo pkg install $package";

   return $self->system($cmd);
}

sub update {
   my $self = shift;

   my $cmd = "sudo pkg update";

   return $self->system($cmd);
}

sub upgrade {
   my $self = shift;

   my $cmd = "sudo pkg upgrade";

   return $self->system($cmd);
}

sub list {
   my $self = shift;

   my $cmd = "pkg info";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Package - system::freebsd::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

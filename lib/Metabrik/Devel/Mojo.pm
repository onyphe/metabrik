#
# $Id$
#
# devel::mojo Brik
#
package Metabrik::Devel::Mojo;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
      },
      commands => {
         generate_lite_app => [ qw(file_pl) ],
         generate_app => [ qw(ModuleName) ],
      },
      require_modules => {
         Mojolicious => [ ],
      },
      require_binaries => {
         mojo => [ ],
      },
   };
}

sub generate_lite_app {
   my $self = shift;
   my ($pl) = @_;

   my $she = $self->shell;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('generate_lite_app', $pl) or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "mojo generate lite_app \"$pl\"";
   my $r = $self->execute($cmd);

   $she->run_cd($cwd) or return;

   return $r;
}

sub generate_app {
   my $self = shift;
   my ($module) = @_;

   my $she = $self->shell;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('generate_app', $module) or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "mojo generate app \"$module\"";
   my $r = $self->execute($cmd);

   $she->run_cd($cwd) or return;

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Devel::Mojo - devel::mojo Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

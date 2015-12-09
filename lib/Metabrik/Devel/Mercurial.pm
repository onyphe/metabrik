#
# $Id$
#
# devel::mercurial Brik
#
package Metabrik::Devel::Mercurial;
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
         capture_mode => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
         use_pager => [ qw(0|1) ],
      },
      attributes_default => {
         capture_mode => 0,
         use_sudo => 0,
         use_pager => 1,
      },
      commands => {
         clone => [ qw(repository) ],
         push => [ ],
         pull => [ ],
         diff => [ qw(directory|file|OPTIONAL) ],
         add => [ qw(directory|file) ],
         commit => [ qw(directory|file|OPTIONAL) ],
         stat => [ qw(directory|OPTIONAL) ],
         modified => [ qw(directory|OPTIONAL) ],
      },
      require_binaries => {
         'hg' => [ ],
      },
   };
}

sub clone {
   my $self = shift;
   my ($repository) = @_;

   $self->brik_help_run_undef_arg("clone", $repository) or return;

   my $cmd = "hg clone $repository";

   return $self->execute($cmd);
}

sub push {
   my $self = shift;

   my $prev = $self->use_pager;

   $self->use_pager(0);
   my $cmd = "hg push";
   my $r = $self->execute($cmd);

   $self->use_pager($prev);

   return $r;
}

sub pull {
   my $self = shift;

   my $cmd = "hg pull -u";

   return $self->execute($cmd);
}

sub diff {
   my $self = shift;
   my ($data) = @_;

   $data ||= '.';
   my $ref = $self->brik_help_run_invalid_arg('diff', $data, 'ARRAY', 'SCALAR') or return;
   if ($ref eq 'ARRAY') {
      $data = join(' ', @$data);
   }

   my $cmd = "hg diff $data";

   return $self->execute($cmd);
}

sub add {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('add', $data) or return;
   my $ref = $self->brik_help_run_invalid_arg('add', $data, 'ARRAY', 'SCALAR') or return;
   if ($ref eq 'ARRAY') {
      $data = join(' ', @$data);
   }

   my $prev = $self->use_pager;

   $self->use_pager(0);
   my $cmd = "hg add $data";
   my $r = $self->execute($cmd);

   $self->use_pager($prev);

   return $r;
}

sub commit {
   my $self = shift;
   my ($data) = @_;

   $data ||= '.';
   my $ref = $self->brik_help_run_invalid_arg('commit', $data, 'ARRAY', 'SCALAR') or return;
   if ($ref eq 'ARRAY') {
      $data = join(' ', @$data);
   }

   my $prev = $self->use_pager;

   $self->use_pager(0);
   my $cmd = "hg commit $data";
   my $r = $self->execute($cmd);

   $self->use_pager($prev);

   return $r;
}

sub stat {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '.';
   $self->brik_help_run_directory_not_found('stat', $directory) or return;

   my $cmd = "hg stat $directory";

   return $self->execute($cmd);
}

sub modified {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '.';
   $self->brik_help_run_directory_not_found('modified', $directory) or return;

   my $cmd = "hg stat -m $directory";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Devel::Mercurial - devel::mercurial Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id$
#
# xorg::screenshot Brik
#
package Metabrik::Xorg::Screenshot;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable screenshot) ],
      attributes => {
         datadir => [ qw(datadir) ],
         output => [ qw(output) ],
      },
      attributes_default => {
         output => 'screenshot-001.png',
      },
      commands => {
         active_window => [ qw(output|OPTIONAL) ],
         full_screen => [ qw(output|OPTIONAL) ],
         select_window => [ qw(output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Find' => [ ],
      },
      require_binaries => {
         'scrot' => [ ],
      },
   };
}

sub _get_new_output {
   my $self = shift;

   my $datadir = $self->datadir;

   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   my $files = $ff->files($datadir, 'screenshot-\d+\.png') or return;

   if (@$files == 0) {
      return "$datadir/screenshot-001.png"; # First output file
   }

   my @sorted = sort { $a cmp $b } @$files;
   my ($id) = $sorted[-1] =~ m{screenshot-(\d+)\.png};

   return $self->output(sprintf("$datadir/screenshot-%03d.png", $id + 1));
}

sub active_window {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->_get_new_output;

   $self->log->verbose("active_window: saving to file [$output]");

   my $cmd = "scrot --focused --border $output";
   $self->system($cmd);

   return $output;
}

sub full_screen {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->_get_new_output;

   $self->log->verbose("full_screen: saving to file [$output]");

   my $cmd = "scrot $output";
   $self->system($cmd);

   return $output;
}

sub select_window {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->_get_new_output;

   $self->log->verbose("select_window: saving to file [$output]");

   my $cmd = "scrot --select --border $output";
   $self->system($cmd);

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::Xorg::Screenshot - xorg::screenshot Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

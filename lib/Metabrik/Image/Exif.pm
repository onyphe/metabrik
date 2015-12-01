#
# $Id$
#
# image::exif Brik
#
package Metabrik::Image::Exif;
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
      },
      attributes_default => {
         capture_mode => 1,
      },
      commands => {
         get_metadata => [ qw(file) ],
      },
      require_binaries => {
         'exif' => [ ],
      },
   };
}

sub get_metadata {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg("get_metadata", $file) or return;
   $self->brik_help_run_file_not_found("get_metadata", $file) or return;

   my $cmd = "exif $file";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Image::Exif - image::exif Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

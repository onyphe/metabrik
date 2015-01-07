#
# $Id$
#
# convert::video Brik
#
package Metabrik::Convert::Video;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable convert avi jpg) ],
      attributes => {
         datadir => [ qw(directory) ],
         input => [ qw(file) ],
         output_pattern => [ qw(file_pattern) ],
      },
      commands => {
         to_jpg => [ ],
      },
      require_binaries => {
         'ffmpeg' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->global->datadir.'/convert-video';

   return {
      attributes_default => {
         datadir => $datadir,
         input => 'VIDEO.MP4',
         output_pattern => 'image_%04d.jpg',
      },
   };
}

sub brik_init {
   my $self = shift;

   my $dir = $self->datadir;
   if (! -d $dir) {
      mkdir($dir)
         or return $self->log->error("brik_init: mkdir failed for dir [$dir]");
   }

   return $self->SUPER::brik_init(@_);
}

sub to_jpg {
   my $self = shift;

   my $input = $self->input;
   my $datadir = $self->datadir;
   my $output_pattern = $self->output_pattern;

   if (! -f $input) {
      return $self->log->error("to_jpg: File [$input] not found");
   }

   # This program is only provided for compatibility and will be removed in a future release.
   # Please use avconv instead.
   my $cmd = "ffmpeg -i $input $datadir/".$output_pattern;

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Convert::Video - convert::video Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

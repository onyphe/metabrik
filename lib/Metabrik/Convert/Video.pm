#
# $Id$
#
# convert::video Brik
#
package Metabrik::Convert::Video;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable convert avi jpg) ],
      attributes => {
         input => [ qw(file) ],
         output_pattern => [ qw(file_pattern) ],
         output_directory => [ qw(directory) ],
      },
      commands => {
         to_jpg => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => 'VIDEO.MP4',
         output_pattern => 'image_%04d.jpg',
         output_directory => $self->global->datadir,
      },
   };
}

sub to_jpg {
   my $self = shift;

   my $input = $self->input;
   my $output_directory = $self->output_directory;
   my $output_pattern = $self->output_pattern;

   if (! -f $input) {
      return $self->log->error("to_jpg: File [$input] not found");
   }

   # This program is only provided for compatibility and will be removed in a future release.
   # Please use avconv instead.
   my $cmd = "ffmpeg -i $input $output_directory/".$output_pattern;
   system("$cmd");

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Convert::Video - convert::video Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

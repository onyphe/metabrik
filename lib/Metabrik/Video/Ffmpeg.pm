#
# $Id$
#
# video::ffmpeg Brik
#
package Metabrik::Video::Ffmpeg;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         resolution => [ qw(resolution) ],
      },
      attributes_default => {
         resolution => '1024x768',
      },
      commands => {
         install => [ ],  # Inherited
         record_desktop => [ qw(output.mkv) ],
         convert_to_youtube => [ qw(input.mkv output.mp4) ],
      },
      require_binaries => {
         ffmpeg => [ ],
      },
      need_packages => {
         ubuntu => [ qw(ffmpeg) ],
      },
   };
}

sub record_desktop {
   my $self = shift;
   my ($output, $resolution) = @_;

   $resolution ||= $self->resolution;
   $self->brik_help_run_undef_arg('record_desktop', $output) or return;

   my $cmd = "ffmpeg -f x11grab -r 25 -s $resolution -i :0.0 ".
      "-vcodec libx264 -preset ultrafast -crf 0 -threads 0 \"$output\"";

   return $self->execute($cmd);
}

sub convert_to_youtube {
   # ffmpeg -i video.mkv -vcodec libx264 -vpre hq -crf 22 -threads 0 video.mp4
}

# With audio
# ffmpeg -f alsa -ac 2 -i hw:0,0 -f x11grab -r 30 -s $(xwininfo -root | grep 'geometry' | awk '{print $2;}') -i :0.0 -acodec pcm_s16le -vcodec libx264 -preset ultrafast -y output.mkv
# ffmpeg -f alsa -i pulse -f x11grab -r 25 -s 1280x720 -i :0.0+0,24 -acodec pcm_s16le -vcodec libx264 -preset ultrafast -threads 0 output.mkv

1;

__END__

=head1 NAME

Metabrik::Video::Ffmpeg - video::ffmpeg Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

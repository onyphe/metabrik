#
# $Id$
#
# file::fetch Brik
#
package Metabrik::File::Fetch;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable fetch wget) ],
      attributes => {
         output => [ qw(file) ],
      },
      commands => {
         get => [ qw(uri output|OPTIONAL) ],
         md5sum => [ qw(file|OPTIONAL) ],
         sha1sum => [ qw(file|OPTIONAL) ],
      },
      require_binaries => {
         'wget' => [ ],
         'md5sum' => [ ],
         'sha1sum' => [ ],
      },
   };
}

sub get {
   my $self = shift;
   my ($uri, $output) = @_;

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $cmd = "wget --output-document=$output $uri";

   return $self->system($cmd);
}

sub md5sum {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->output;
   if (! defined($file)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   my $cmd = "md5sum $file";
   $self->as_matrix(1);
   my $buf = $self->capture($cmd);

   return $buf->[0][0];
}

sub sha1sum {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->output;
   if (! defined($file)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   my $cmd = "sha1sum $file";
   $self->as_matrix(1);
   my $buf = $self->capture($cmd);

   return $buf->[0][0];
}

1;

__END__

=head1 NAME

Metabrik::File::Fetch - file::fetch Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

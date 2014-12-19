#
# $Id$
#
# file::zip brik
#
package Metabrik::File::Compress;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable compress unzip gunzip uncompress) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         destdir => [ qw(directory) ],
      },
      commands => {
         unzip => [ ],
         gunzip => [ ],
      },
      require_binaries => {
         'unzip' => [ ],
         'gunzip' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         destdir => $self->global->datadir,
      },
   };
}

sub unzip {
   my $self = shift;
   my ($file, $destdir) = @_;

   $file ||= $self->input;
   if (! defined($file)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   $destdir ||= $self->destdir;
   if (! defined($destdir)) {
      return $self->log->error($self->brik_help_set('destdir'));
   }

   my $cmd = "unzip -o $file -d $destdir/";

   return $self->system($cmd);
}

sub gunzip {
   my $self = shift;
   my ($file, $destdir) = @_;

   $file ||= $self->input;
   if (! defined($file)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   $destdir ||= $self->destdir;
   if (! defined($destdir)) {
      return $self->log->error($self->brik_help_set('destdir'));
   }

   (my $file_out = $file) =~ s/.gz$//;

   my $cmd = "gunzip -c $file > $file_out";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::File::Compress - file::compress Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

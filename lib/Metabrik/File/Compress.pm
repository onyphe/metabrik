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
         datadir => [ qw(directory) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      commands => {
         unzip => [ qw(input|OPTIONAL datadir|OPTIONAL) ],
         gunzip => [ qw(input|OPTIONAL output|OPTIONAL) ],
      },
      require_binaries => {
         'unzip' => [ ],
         'gunzip' => [ ],
      },
   };
}

sub unzip {
   my $self = shift;
   my ($input, $datadir) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   $datadir ||= $self->datadir;

   my $cmd = "unzip -o $input -d $datadir/";

   return $self->system($cmd);
}

sub gunzip {
   my $self = shift;
   my ($input, $output) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   my $file_out;
   if (defined($output)) {
      $file_out = $output;
   }
   else {
      ($file_out = $input) =~ s/.gz$//;
   }

   my $cmd = "gunzip -c $input > $file_out";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::File::Compress - file::compress Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

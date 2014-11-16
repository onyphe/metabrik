#
# $Id$
#
# file::zip brik
#
package Metabrik::File::Compress;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable compress unzip uncompress) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         destdir => [ qw(directory) ],
      },
      commands => {
         unzip => [ ],
      },
      require_used => {
         'shell::command' => [ ],
      },
      require_binaries => {
         'unzip' => [ ],
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
   my ($destdir) = @_;

   my $input = $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   my $dir = $self->destdir;
   if (! defined($dir)) {
      return $self->log->error($self->brik_help_set('destdir'));
   }

   my $cmd = "unzip -o $input -d $dir/";

   return $self->context->run('shell::command', 'system', $cmd);
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

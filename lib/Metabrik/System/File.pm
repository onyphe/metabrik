#
# $Id$
#
# system::file Brik
#
package Metabrik::System::File;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable system file chmod chgrp cp copy move rm mv remove mkdir mkd magic) ],
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         identify => [ qw(file) ],
         mkdir => [ qw(directory) ],
         rmdir => [ qw(directory) ],
         chmod => [ qw(file) ],
         chgrp => [ qw(file) ],
         copy => [ qw(source destination) ],
         move => [ qw(source destination) ],
         remove => [ qw(file) ],
         rename => [ qw(source destination) ],
         cat => [ qw(source destination) ],
      },
      require_modules => {
         'File::MMagic' => [ ],
         'File::Copy' => [ qw(mv) ],
         'File::Spec' => [ ],
         'File::Path' => [ ],
      },
   };
}

sub identify {
   my $self = shift;
   my ($file) = @_;

   return 1;
}

sub mkdir {
   my $self = shift;
   my ($path) = @_;

   if (! defined($path)) {
      return $self->log->error($self->brik_help_run('mkdir'));
   }

   my $no_error = 1;
   File::Path::make_path($path, { error => \my $error });
   if ($error) {
      for my $this (@$error) {
         my ($file, $message) = %$this;
         if ($file eq '') {
            return $self->log->error("mkdir: make_path failed with error [$message]");
         }
         else {
            $self->log->warning("mkdir: error creating directory [$file]: error [$error]");
            $no_error = 0;
         }
      }
   }

   return $no_error;
}

sub move {
#eval('use File::Copy qw(mv);');
}

sub cat {
#File::Spec->catfile(source, dest)
}

1;

__END__

=head1 NAME

Metabrik::System::File - system::file Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

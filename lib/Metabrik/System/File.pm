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
      tags => [ qw(unstable chmod chgrp cp copy move rm mv remove mkdir mkd magic) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         overwrite => 0,
      },
      commands => {
         mkdir => [ qw(directory) ],
         rmdir => [ qw(directory) ],
         chmod => [ qw(file) ],
         chgrp => [ qw(file) ],
         copy => [ qw(source destination) ],
         move => [ qw(source destination) ],
         remove => [ qw(file|$file_list) ],
         rename => [ qw(source destination) ],
         cat => [ qw(source destination) ],
         create => [ qw(file size) ],
         glob => [ qw(pattern) ],
      },
      require_modules => {
         'File::Copy' => [ qw(mv) ],
         'File::Path' => [ qw(make_path) ],
         'File::Spec' => [ ],
      },
   };
}

sub mkdir {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg('mkdir', $path) or return;

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

sub remove {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('remove', $file) or return;
   my $ref = $self->brik_help_run_invalid_arg('remove', $file, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      for my $this (@$file) {
         unlink($this) or $self->log->warning("remove: unable to unlink file [$file]: $!");
      }
   }
   else {
      unlink($file) or return $self->log->warning("remove: unable to unlink file [$file]: $!");
   }

   return $file;
}

sub move {
#eval('use File::Copy qw(mv);');
}

sub cat {
#File::Spec->catfile(source, dest)
}

sub create {
   my $self = shift;
   my ($file, $size) = @_;

   $self->brik_help_run_undef_arg("create", $file) or return;
   $self->brik_help_run_undef_arg("create", $size) or return;

   my $overwrite = $self->overwrite;
   if (-f $file && ! $self->overwrite) {
      return $self->log->error("create: file [$file] already exists, use overwrite Attribute");
   }

   if (-f $file) {
      $self->remove($file) or return;
   }

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->overwrite(1);
   $fw->open($file) or return;
   $fw->write(sprintf("G"x$size));
   $fw->close;

   return 1;
}

sub glob {
   my $self = shift;
   my ($pattern) = @_;

   my @list = CORE::glob("$pattern");

   return \@list;
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

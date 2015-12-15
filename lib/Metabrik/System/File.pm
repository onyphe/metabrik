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
         get_mime_type => [ qw(file) ],
         get_magic_type => [ qw(file) ],
         is_mime_type => [ qw(file mime_type) ],
         is_magic_type => [ qw(file mime_type) ],
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
      },
      require_modules => {
         'File::Copy' => [ qw(mv) ],
         'File::LibMagic' => [ ],
         'File::Path' => [ qw(make_path) ],
         'File::Spec' => [ ],
      },
   };
}

sub get_mime_type {
   my $self = shift;
   my ($files) = @_;

   $self->brik_help_run_undef_arg('get_mime_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('get_mime_type', $files, 'ARRAY', 'SCALAR') or return;

   my $magic = File::LibMagic->new;

   if ($ref eq 'ARRAY') {
      my $types = {};
      for my $file (@$files) {
         my $type = $self->get_mime_type($file) or next;
         $types->{$file} = $type;
      }

      return $types;
   }
   else {
      $self->brik_help_run_file_not_found('get_mime_type', $files) or return;
      my $info = $magic->info_from_filename($files);

      return $info->{mime_type};
   }

   # Error
   return;
}

sub get_magic_type {
   my $self = shift;
   my ($files) = @_;

   $self->brik_help_run_undef_arg('get_magic_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('get_magic_type', $files, 'ARRAY', 'SCALAR') or return;

   my $magic = File::LibMagic->new;

   if ($ref eq 'ARRAY') {
      my $types = {};
      for my $file (@$files) {
         my $type = $self->get_magic_type($file) or next;
         $types->{$file} = $type;
      }
      return $types;
   }
   else {
      $self->brik_help_run_file_not_found('get_magic_type', $files) or return;
      my $info = $magic->info_from_filename($files);
      return $info->{description};
   }

   # Error
   return;
}

sub is_mime_type {
   my $self = shift;
   my ($files, $mime_type) = @_;

   $self->brik_help_run_undef_arg('is_mime_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('is_mime_type', $files, 'ARRAY', 'SCALAR')
      or return;

   my $types = {};
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('is_mime_type', $files) or return;
      for my $file (@$files) {
         my $res = $self->is_mime_type($file, $mime_type) or next;
         $types->{$files} = $res;
      }
   }
   else {
      my $type = $self->get_mime_type($files, $mime_type) or return;
      if ($type eq $mime_type) {
         $types->{$files} = 1;
      }
      else {
         $types->{$files} = 0;
      }
   }

   return $ref eq 'ARRAY' ? $types : $types->{$files};
}

sub is_magic_type {
   my $self = shift;
   my ($files, $magic_type) = @_;

   $self->brik_help_run_undef_arg('is_magic_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('is_magic_type', $files, 'ARRAY', 'SCALAR')
      or return;

   my $types = {};
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('is_magic_type', $files) or return;
      for my $file (@$files) {
         my $res = $self->is_magic_type($file, $magic_type) or next;
         $types->{$files} = $res;
      }
   }
   else {
      my $type = $self->get_magic_type($files, $magic_type) or return;
      if ($type eq $magic_type) {
         $types->{$files} = 1;
      }
      else {
         $types->{$files} = 0;
      }
   }

   return $ref eq 'ARRAY' ? $types : $types->{$files};
}

sub mkdir {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg("mkdir", $path) or return;

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

   $self->brik_help_run_undef_arg("remove", $file) or return;
   my $ref = $self->brik_help_run_invalid_arg("remove", $file, 'ARRAY', 'SCALAR') or return;

   if ($ref eq 'ARRAY') {
      unlink(@$file) or return $self->log->error("remove: unable to unlink files: [$!]");
   }
   else {
      unlink($file) or return $self->log->error("remove: unable to unlink file: [$!]");
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

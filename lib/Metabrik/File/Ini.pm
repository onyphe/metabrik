#
# $Id$
#
# file::ini Brik
#
package Metabrik::File::Ini;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable ini file) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         encoding => 'utf8',
         overwrite => 1,
      },
      commands => {
         read => [ qw(input|OPTIONAL) ],
         write => [ qw(ini_hash output|OPTIONAL) ],
      },
      require_modules => {
         'Config::Tiny' => [ ],
         'Metabrik::String::Ini' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   my $file_text = Metabrik::File::Text->new_from_brik($self) or return;
   $file_text->encoding($self->encoding);

   my $string = $file_text->read($input)
      or return $self->log->error("read: read failed");

   my $string_ini = Metabrik::String::Ini->new_from_brik($self) or return;

   my $ini_hash = $string_ini->decode($string)
      or return $self->log->error("read: decode failed");

   return $ini_hash;
}

sub write {
   my $self = shift;
   my ($ini_hash, $output) = @_;

   if (! defined($ini_hash)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   if (ref($ini_hash) ne 'HASH') {
      return $self->log->error("write: argument 1 must be HASHREF");
   }

   my $string_ini = Metabrik::String::Ini->new_from_brik($self) or return;

   my $string = $string_ini->encode($ini_hash)
      or return $self->log->error("write: encode failed");

   my $file_text = Metabrik::File::Text->new_from_brik($self) or return;
   $file_text->encoding($self->encoding);

   $file_text->write($string, $output)
      or return $self->log->error("write: write failed");

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Ini - file::ini Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

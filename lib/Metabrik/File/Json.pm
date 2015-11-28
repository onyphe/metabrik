#
# $Id$
#
# file::json Brik
#
package Metabrik::File::Json;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         overwrite => 1,
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw($json_hash output_file|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Write' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input || '/tmp/input.txt',
         output => $self->global->output || '/tmp/output.txt',
         encoding => $self->global->encoding || 'utf8',
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

   my $data = $self->read($input)
      or return $self->log->error("read: read failed");

   my $string_json = Metabrik::String::Json->new_from_brik($self) or return;

   my $json = $string_json->decode($data)
      or return $self->log->error("read: decode failed");

   return $json;
}

sub write {
   my $self = shift;
   my ($json_hash, $output) = @_;

   if (! defined($json_hash)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   my $string_json = Metabrik::String::Json->new_from_brik($self) or return;

   my $data = $string_json->encode($json_hash)
      or return $self->log->error("write: encode failed");

   $self->write($data, $output)
      or return $self->log->error("write: write failed");

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Json - file::json Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

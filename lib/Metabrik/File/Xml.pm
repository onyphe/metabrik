#
# $Id$
#
# file::xml Brik
#
package Metabrik::File::Xml;
use strict;
use warnings;

use base qw(Metabrik::File::Read);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         overwrite => 1,
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw($xml_hash output_file|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Write' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input || '/tmp/input.xml',
         output => $self->global->output || '/tmp/output.xml',
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

   $self->open($input) or return $self->log->error("read: open failed");
   my $data = $self->read or return $self->log->error("read: read failed");
   $self->close;

   my $xml = Metabrik::String::Xml->new_from_brik($self) or return;
   my $decode = $xml->decode($data) or return $self->log->error("read: decode failed");

   return $decode;
}

sub write {
   my $self = shift;
   my ($xml_hash, $output) = @_;

   $output ||= $self->output;

   if (! defined($xml_hash)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   my $xml = Metabrik::String::Xml->new_from_brik($self) or return;
   my $data = $xml->encode($xml_hash) or return $self->log->error("write: encode failed");

   my $write = Metabrik::File::Write->new_from_brik($self) or return;
   $write->open($output) or return $self->log->error("write: open failed");
   $write->write($data) or return $self->log->error("write: write failed");
   $write->close;

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::File::Xml - file::xml Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

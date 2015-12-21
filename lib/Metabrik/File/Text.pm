#
# $Id$
#
# file::text Brik
#
package Metabrik::File::Text;
use strict;
use warnings;

use base qw(Metabrik::File::Write);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable read write) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         as_array => [ qw(0|1) ],
         strip_crlf => [ qw(0|1) ],
      },
      # encoding: see `perldoc Encode::Supported' for other types
      attributes_default => {
         encoding => 'utf8',
         as_array => 0,
         strip_crlf => 0,
      },
      commands => {
         read => [ qw(input) ],
         read_split_by_blank_line => [ qw(input) ],
         write => [ qw($data|$data_ref|$data_list output) ],
      },
      require_modules => {
         'Metabrik::File::Read' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('read'));
   }

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->input($input);
   $fr->encoding($self->encoding);
   $fr->as_array($self->as_array);
   $fr->strip_crlf($self->strip_crlf);

   $fr->open or return;
   my $data = $fr->read or return;
   $fr->close;

   return $data;
}

sub read_split_by_blank_line {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('read_split_by_blank_line'));
   }

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->input($input);
   $fr->encoding($self->encoding);
   $fr->as_array($self->as_array);
   $fr->strip_crlf($self->strip_crlf);

   $fr->open or return;

   my @chunks = ();
   while (my $this = $fr->read_until_blank_line) {
      push @chunks, $this;
      last if $fr->eof;
   }

   $fr->close;

   return \@chunks;
}

sub write {
   my $self = shift;
   my ($data, $output) = @_;

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_run('write'));
   }
   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $self->debug && $self->log->debug("write: data[$data]");

   $self->open($output) or return;
   $self->SUPER::write($data) or return;
   $self->close;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Text - file::text Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

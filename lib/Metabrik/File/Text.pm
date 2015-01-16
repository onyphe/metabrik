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
      tags => [ qw(unstable file text read write) ],
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      commands => {
         read => [ qw(file) ],
         write => [ qw($data|$data_ref|$data_list output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Read' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   # encoding: see `perldoc Encode::Supported' for other types
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

   my $read = Metabrik::File::Read->new_from_brik($self);
   $read->input($input);
   $read->encoding($self->encoding);
   $read->open or return $self->log->error("read: open failed");
   my $data = $read->readall or return $self->log->error("read: read failed");
   $read->close;

   return $data;
}

sub write {
   my $self = shift;
   my ($data, $output) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $output ||= $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   $self->debug && $self->log->debug("write: data[$data]");

   $self->open($output) or return $self->log->error("write: open failed");
   my $r = $self->SUPER::write($data);
   if (! defined($r)) {
      return $self->log->error("write: write failed");
   }
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

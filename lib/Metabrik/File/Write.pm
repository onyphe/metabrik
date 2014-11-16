#
# $Id$
#
# file::write Brik
#
package Metabrik::File::Write;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable file) ],
      attributes => {
         output => [ qw(file) ],
         append => [ qw(0|1) ],
         overwrite => [ qw(0|1) ],
         encoding => [ qw(utf8|ascii) ],
         fd => [ qw(file_descriptor) ],
      },
      commands => {
         open => [ ],
         write => [ qw($data|$data_ref) ],
         close => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   # encoding: see `perldoc Encode::Supported' for other types
   return {
      attributes_default => {
         output => $self->global->output || '/tmp/output.txt',
         append => 1,
         overwrite => 0,
         encoding => $self->global->encoding || 'utf8',
      },
   };
}

sub open {
   my $self = shift;

   my $output = $self->output;
   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

   my $out;
   my $encoding = $self->encoding;
   if ($self->append) {
      my $r = open($out, ">>$encoding", $output);
      if (! defined($r)) {
         return $self->log->error("open: open: append file [$output]: $!");
      }
   }
   elsif (! $self->append && $self->overwrite) {
      my $r = open($out, ">$encoding", $output);
      if (! defined($r)) {
         return $self->log->error("open: open: write file [$output]: $!");
      }
   }
   elsif (! $self->append && ! $self->overwrite && -f $self->output) {
      $self->log->info("open: we will not overwrite an existing file. See:");
      return $self->log->error($self->brik_help_set('overwrite'));
   }

   return $self->fd($out);
}

sub close {
   my $self = shift;

   if (defined($self->fd)) {
      close($self->fd);
      $self->fd(undef);
   }

   return 1;
}

sub write {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('write'));
   }

   $self->debug && $self->log->debug("write: data[$data]");

   my $fd = $self->fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   ref($data) eq 'SCALAR' ? print $fd $$data : print $fd $data;

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::File::Write - file::write Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

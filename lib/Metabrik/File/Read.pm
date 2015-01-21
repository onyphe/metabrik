#
# $Id$
#
# file::read Brik
#
package Metabrik::File::Read;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable file) ],
      attributes => {
         input => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         fd => [ qw(file_descriptor) ],
         as_array => [ qw(0|1) ],
         eof => [ qw(0|1) ],
         count => [ qw(count) ],
      },
      attributes_default => {
         as_array => 0,
         eof => 0,
         count => 1,
      },
      commands => {
         open => [ qw(file|OPTIONAL) ],
         close => [ ],
         readall => [ ],
         read_until_blank_line => [ ],
         read_line => [ qw(count|OPTIONAL) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input,
         encoding => $self->global->encoding,
      },
   };
}

sub open {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   if (! -f $input) {
      return $self->log->error("open: file [$input] not found");
   }

   my $r;
   my $out;
   my $encoding = $self->encoding || 'ascii';
   if ($encoding eq 'ascii') {
      $r = open($out, '<', $input);
   }
   else {
      $r = open($out, "<$encoding", $input);
   }
   if (! defined($r)) {
      return $self->log->error("open: open: file [$input]: $!");
   }

   return $self->fd($out);
}

sub close {
   my $self = shift;

   if (defined($self->fd)) {
      close($self->fd);
   }

   return 1;
}

sub readall {
   my $self = shift;

   my $fd = $self->fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         chomp;
         push @out, $_;
      }
      $self->eof(1);
      return \@out;
   }
   else {
      my $out = '';
      while (<$fd>) {
         $out .= $_;
      }
      $self->eof(1);
      return $out;
   }

   return;
}

sub read_until_blank_line {
   my $self = shift;

   my $fd = $self->fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         last if /^\s*$/;
         chomp;
         push @out, $_;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return \@out;
   }
   else {
      my $out = '';
      while (<$fd>) {
         last if /^\s*$/;
         $out .= $_;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return $out;
   }

   return;
}

sub read_line {
   my $self = shift;
   my ($count) = @_;

   my $fd = $self->fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   $count ||= $self->count;

   if ($self->as_array) {
      my @out = ();
      my $this = 1;
      while (<$fd>) {
         chomp;
         push @out, $_;
         last if $this == $count;
         $count++;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return \@out;
   }
   else {
      my $out = '';
      my $this = 1;
      while (<$fd>) {
         last if /^\s*$/;
         $out .= $_;
         last if $this == $count;
         $count++;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return $out;
   }

   return;
}

1;

__END__

=head1 NAME

Metabrik::File::Read - file::read Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

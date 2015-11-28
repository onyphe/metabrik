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
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         fd => [ qw(file_descriptor) ],
         as_array => [ qw(0|1) ],
         eof => [ qw(0|1) ],
         count => [ qw(count) ],
         strip_crlf => [ qw(0|1) ],
      },
      attributes_default => {
         as_array => 0,
         eof => 0,
         count => 1,
         strip_crlf => 1,
      },
      commands => {
         open => [ qw(file|OPTIONAL) ],
         close => [ ],
         read => [ ],
         read_until_blank_line => [ ],
         read_line => [ qw(count|OPTIONAL) ],
         is_eof => [ ],
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
      $self->eof(0);
   }

   return 1;
}

sub read {
   my $self = shift;

   my $fd = $self->fd;
   if (! defined($fd)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my $strip_crlf = $self->strip_crlf;

   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
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

   my $strip_crlf = $self->strip_crlf;

   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         last if /^\s*$/;
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
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

   my $strip_crlf = $self->strip_crlf;

   if ($self->as_array) {
      my @out = ();
      my $this = 1;
      while (<$fd>) {
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
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
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
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

sub is_eof {
   my $self = shift;

   return $self->eof;
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

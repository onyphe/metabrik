#
# $Id$
#
# file::pcap Brik
#
package Metabrik::File::Pcap;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable frame packet) ],
      attributes => {
         input => [ qw(input) ],
         eof => [ qw(0|1) ],
         count => [ qw(count) ],
         filter => [ qw(filter) ],
         _dump => [ qw(INTERNAL) ],
      },
      attributes_default => {
         eof => 0,
         filter => '',
      },
      commands => {
         open => [ qw(input filter|OPTIONAL) ],
         close => [ ],
         read => [ ],
         read_next => [ qw(count|OPTIONAL) ],
         is_eof => [ ],
      },
      require_modules => {
         'Net::Frame::Dump::Offline' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($input, $filter) = @_;

   if ($self->_dump) {
      return $self->log->error("open: already opened");
   }

   $input ||= $self->input;
   $filter ||= $self->filter;
   if (! defined($input)) {
      return $self->log->error($self->brik_help_run('open'));
   }
   if (! -f $input) {
      return $self->log->error("open: input [$input] not found");
   }

   my $dump = Net::Frame::Dump::Offline->new(
      file => $input,
      filter => $filter,
   );

   $dump->start or return $self->log->error("open: start failed");

   return $self->_dump($dump);
}

sub close {
   my $self = shift;

   my $dump = $self->_dump;
   if (defined($dump)) {
      $dump->stop;
      $self->eof(0);
      $self->_dump(undef);
   }

   return 1;
}

# Will read everything until the end-of-file
sub read {
   my $self = shift;

   if ($self->is_eof) {
      return $self->log->error("read: end-of-file already reached");
   }

   my $dump = $self->_dump;
   if (! defined($dump)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my @h = ();
   {
      # So we can interrupt execution
      #local $SIG{INT} = sub {
         #die("interrupted by user\n");
      #};

      while (my $h = $dump->next) {
         push @h, $h;
      }

      $self->eof(1);
   }

   return \@h;
}

sub read_next {
   my $self = shift;
   my ($count) = @_;

   $count ||= 1;
   my $dump = $self->_dump;
   if (! defined($dump)) {
      return $self->log->error($self->brik_help_run('open'));
   }

   my @h = ();
   my $read = 0;
   while (my $h = $dump->next) {
      push @h, $h;
      last if ++$read == $count;
   }

   return \@h;
}

sub is_eof {
   my $self = shift;

   return $self->eof;
}

1;

__END__

=head1 NAME

Metabrik::File::Pcap - file::pcap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

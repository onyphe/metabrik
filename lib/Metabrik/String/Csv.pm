#
# $Id$
#
# string::csv Brik
#
package Metabrik::String::Csv;
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
         first_line_is_header => [ qw(0|1) ],
         separator => [ qw(character) ],
         header => [ qw($column_header_list) ],
         encoding => [ qw(utf8|ascii) ],
      },
      attributes_default => {
         first_line_is_header => 0,
         header => [ ],
         separator => ';',
         encoding => 'utf8',
      },
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'IO::Scalar' => [ ],
         'Text::CSV_XS' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encode'));
   }

   # We only handle array of hashes format (aoh) for writing
   if (ref($data) ne 'ARRAY') {
      return $self->log->error("encode: csv structure is not ARRAY");
   }

   if (! scalar(@$data)) {
      return $self->log->error("encode: csv structure is empty, nothing to write");
   }

   if (ref($data->[0]) ne 'HASH') {
      return $self->log->error("encode: csv structure does not contain HASHes");
   }

   my $context = $self->context;

   my $output = '';
   my $fd = IO::Scalar->new(\$output);

   my $header_written = 0;
   my %order = ();
   for my $this (@$data) {
      if (! $header_written) {
         my $idx = 0;
         for my $k (sort { $a cmp $b } keys %$this) {
            $order{$k} = $idx;
            $idx++;
         }
         my @header = sort { $a cmp $b } keys %$this;
         my $string = join($self->separator, @header)."\n";
         print $fd $string;
         $header_written++;
      }

      my @fields = ();
      for my $key (sort { $a cmp $b } keys %$this) {
         $fields[$order{$key}] = $this->{$key};
      }

      my $string = join($self->separator, @fields)."\n";
      print $fd $string;
   }

   $fd->close;

   if (! length($output)) {
      return $self->log->error("encode: nothing to encode");
   }

   return $output;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('decode'));
   }

   my $csv = Text::CSV_XS->new({
      binary => 1,
      sep_char => $self->separator,
      allow_loose_quotes => 1,
      allow_loose_escapes => 1,
   }) or return $self->log->error("decode: Text::CSV_XS new failed");

   my $fd = IO::Scalar->new(\$data);

   my $sep = $self->separator;
   my $headers;
   my $count;
   my $first_line = 1;
   my @rows = ();
   while (my $row = $csv->getline($fd)) {
      if ($self->first_line_is_header) {
         if ($first_line) {  # This is first line
            $headers = $row;
            $count = scalar @$row - 1;
            $first_line = 0;
            $self->header($headers);
            next;
         }

         my $h;
         for (0..$count) {
            $h->{$headers->[$_]} = $row->[$_];
         }
         push @rows, $h;
      } 
      else {
         push @rows, $row;
      }
   }

   if (! $csv->eof) {
      my $error_str = "".$csv->error_diag();
      $self->log->error("read: incomplete: error [$error_str]");
      return \@rows;
   }

   return \@rows;
}

1;

__END__

=head1 NAME

Metabrik::String::Csv - string::csv Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id$
#
# file::csv Brik
#
package Metabrik::File::Csv;
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
         output => [ qw(file) ],
         first_line_is_header => [ qw(0|1) ],
         separator => [ qw(character) ],
         header => [ qw($column_header_list) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         first_line_is_header => 1,
         header => [ ],
         separator => ';',
         encoding => 'utf8',
         overwrite => 1,
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw(csv_struct output_file|OPTIONAL) ],
         get_column_values => [ qw($data column_name|column_int) ],
      },
      require_modules => {
         'Text::CSV_XS' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Write' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg("read", $input) or return;

   my $csv = Text::CSV_XS->new({
      binary => 1,
      sep_char => $self->separator,
      allow_loose_quotes => 1,
      allow_loose_escapes => 1,
   }) or return $self->log->error('read: Text::CSV_XS new failed');

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->encoding($self->encoding);
   my $fd = $fr->open($input) or return;

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

   $fr->close;

   return \@rows;
}

sub write {
   my $self = shift;
   my ($csv_struct, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg("write", $csv_struct) or return;
   $self->brik_help_run_undef_arg("write", $output) or return;

   # We handle handle array of hashes format (aoh) for writing
   if (ref($csv_struct) ne 'ARRAY') {
      return $self->log->error("write: csv structure is not ARRAY");
   }

   if (! scalar(@$csv_struct)) {
      return $self->log->error("write: csv structure is empty, nothing to write");
   }

   if (ref($csv_struct->[0]) ne 'HASH') {
      return $self->log->error("write: csv structure does not contain HASHes");
   }

   my $context = $self->context;

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->output($output);
   $fw->encoding($self->encoding);
   my $fd = $fw->open or return;

   my $written = '';

   my $header_written = 0;
   my %order = ();
   for my $this (@$csv_struct) {
      if (! $header_written) {
         my $idx = 0;
         for my $k (sort { $a cmp $b } keys %$this) {
            $order{$k} = $idx;
            $idx++;
         }
         my @header = sort { $a cmp $b } keys %$this;
         my $data = join($self->separator, @header)."\n";
         print $fd $data;
         $written .= $data;
         $header_written++;
      }

      my @fields = ();
      for my $key (sort { $a cmp $b } keys %$this) {
         $fields[$order{$key}] = $this->{$key};
      }

      my $data = join($self->separator, @fields)."\n";

      my $r = $fw->write($data);
      if (! defined($r)) {
         next;
      }

      $written .= $data;
   }

   $fw->close;

   if (! length($written)) {
      return $self->log->error("write: nothing to write");
   }

   return $written;
}

sub get_column_values {
   my $self = shift;
   my ($data, $column) = @_;

   $self->brik_help_run_undef_arg("get_column_values", $data) or return;
   $self->brik_help_run_undef_arg("get_column_values", $column) or return;

   if (ref($data) ne 'ARRAY') {
      return $self->log->error("get_column_values: arg1 must be ARRAYREF");
   }

   my @results = ();
   # CSV structure is an ARRAYREF of HASHREFs
   if ($self->first_line_is_header) {
      if (@{$self->header} == 0) {
         return $self->log->error("get_column_values: no CSV header found");
      }

      for my $row (@$data) {
         if (ref($row) ne 'HASH') {
            $self->log->warning("get_column_values: row is not a HASHREF");
            next;
         }
         if (exists($row->{$column})) {
            push @results, $row->{$column};
         }
      }
   }
   # CSV structure is an ARRAYREF of ARRAYREFs
   elsif ($column =~ m{^\d+$}) {
      for my $row (@$data) {
         if (ref($row) ne 'ARRAY') {
            $self->log->warning("get_column_values: row is not an ARRAYREF");
            next;
         }
         if (exists($row->[$column])) {
            push @results, $row->[$column];
         }
      }
   }

   return \@results;
}

1;

__END__

=head1 NAME

Metabrik::File::Csv - file::csv Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

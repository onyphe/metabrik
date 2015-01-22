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
      tags => [ qw(unstable csv file) ],
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
         get_col_by_name => [ qw($data|$READ column_name column_value) ],
         get_col_by_number => [ qw($data|$READ integer) ],
      },
      require_modules => {
         'Text::CSV' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Write' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input,
         output => $self->global->output,
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

   my $csv = Text::CSV->new({
      binary => 1,
      sep_char => $self->separator,
      allow_loose_quotes => 1,
      allow_loose_escapes => 1,
   }) or return $self->log->error('read: Text::CSV new failed');

   my $read = Metabrik::File::Read->new_from_brik($self);
   $read->encoding($self->encoding);
   my $fd = $read->open($input)
      or return $self->log->error('read: read failed');

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

   $read->close;

   return \@rows;
}

sub write {
   my $self = shift;
   my ($csv_struct, $output) = @_;

   $output ||= $self->output;

   if (! defined($output)) {
      return $self->log->error($self->brik_help_set('output'));
   }

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

   my $write = Metabrik::File::Write->new_from_brik($self);
   $write->output($output);
   $write->encoding($self->encoding);
   my $fd = $write->open
      or return $self->log->error('write: open failed');

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

      my $r = $write->write($data);
      if (! defined($r)) {
         $self->log->error("write: write failed");
         next;
      }

      $written .= $data;
   }

   $write->close;

   if (! length($written)) {
      return $self->log->error("write: nothing to write");
   }

   return $written;
}

sub get_col_by_name {
   my $self = shift;
   my ($data, $type, $value) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('get_col_by_name'));
   }
   if (! defined($type)) {
      return $self->log->error($self->brik_help_run('get_col_by_name'));
   }
   if (! defined($value)) {
      return $self->log->error($self->brik_help_run('get_col_by_name'));
   }

   if (! $self->first_line_is_header || @{$self->header} == 0) {
      return $self->log->error("get_col_by_name: no CSV header found");
   }

   my @results = ();
   for my $row (@$data) {
      if (exists($row->{$type})) {
         if ($row->{$type} eq $value) {
            push @results, $row;
         }
      }
   }

   return \@results;
}

sub get_col_by_number {
   my $self = shift;
   my ($data, $number) = @_;

   return $self->log->info("XXX: TODO");
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

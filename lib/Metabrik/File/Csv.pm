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
         has_header => [ qw(0|1) ],
         format => [ qw(aoh|hoh) ],
         separator => [ qw(character) ],
         header => [ qw($column_header_list) ],
         key => [ qw(key) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         has_header => 0,
         header => [ ],
         format => 'aoh',
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
         'Text::CSV::Hashify' => [ ],
      },
      require_used => {
         'file::write' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input || '/tmp/input.txt',
         output => $self->global->output || '/tmp/output.txt',
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

   my $format = $self->format;
   if ($format !~ /^aoh$/ && $format !~ /^hoh$/) {
      return $self->log->error($self->brik_help_set('format'));
   }

   my $key = $self->key;

   my $data = Text::CSV::Hashify->new({
      file => $input,
      format => $format,
      sep_char => $self->separator,
      key => $key,
   }) or return $self->log->error("Text::CSV::Hashify: new");

   return $data->all;
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

   $context->save_state('file::write')
      or return $self->log->error("write: file::write save_state failed");

   $context->set('file::write', 'output', $output)
      or return $self->log->error('write: file::write set output failed');
   my $fd = $context->run('file::write', 'open')
      or return $self->log->error('write: file::write run open failed');

   my $written = '';

   my $header_written = 0;
   for my $this (@$csv_struct) {
      if (! $header_written) {
         my @header = keys %$this;
         my $data = join($self->separator, @header)."\n";
         print $fd $data;
         $written .= $data;
         $header_written++;
      }

      my @fields = ();
      for my $key (keys %$this) {
         push @fields, $this->{$key};
      }

      my $data = join($self->separator, @fields)."\n";

      my $r = $context->run('file::write', 'write', $data);
      if (! defined($r)) {
         $self->log->error("write: file::write write failed");
         next;
      }

      $written .= $data;
   }

   $context->run('file::write', 'close');

   $context->restore_state('file::write')
      or return $self->log->error("write: file::write save_state failed");

   if (! length($written)) {
      return $self->log->error("write: nothing to write");
   }

   return $written;
}

sub get_col_by_name {
   my $self = shift;
   my ($data, $type, $value) = @_;

   if (! $self->has_header || @{$self->header} == 0) {
      return $self->log->error("CSV has no header, can't do that");
   }

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('read'));
   }

   if (! defined($type)) {
      return $self->log->error($self->brik_help_run('get_col_by_name'));
   }

   if (! defined($value)) {
      return $self->log->error($self->brik_help_run('get_col_by_name'));
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

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

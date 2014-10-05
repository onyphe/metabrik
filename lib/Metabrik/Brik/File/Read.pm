#
# $Id$
#
# file::read Brik
#
package Metabrik::Brik::File::Read;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return [ qw(input csv_has_header csv_format csv_separator csv_header) ];
}

sub require_modules {
   return {
      'File::Slurp' => [],
      'JSON::XS' => [],
      'XML::Simple' => [],
      'Text::CSV::Hashify' => [],
   };
}

sub help {
   return {
      'set:input' => '<file>',
      'set:csv_has_header' => '<0|1>',
      'set:csv_header' => '<header1:header2:..:headerN>',
      'set:csv_format' => '<aoh|..> (default: aoh)',
      'set:csv_separator' => '<separator>',
      'run:text' => '',
      'run:json' => '',
      'run:xml' => '',
      'run:csv' => '',
      'run:csv_get_col_by_name' => '<data> <type> <value>',
      'run:csv_get_col_by_number' => '<data> <number>',
   };
}

sub default_values {
   return {
      input => $_[0]->global->input || '/tmp/input.txt',
      csv_has_header => 0,
      csv_header => [ ],
      csv_format => 'aoh',
      csv_separator => ';',
   };
}

sub text {
   my $self = shift;

   if (! defined($self->input)) {
      return $self->log->info($self->help_set('input'));
   }

   my $text = File::Slurp::read_file($self->input)
      or return $self->log->verbose("nothing to read from input [".$self->file."]");

   return $text;
}

sub json {
   my $self = shift;

   if (! defined($self->input)) {
      return $self->log->info($self->help_set('input'));
   }

   return JSON::XS::decode_json($self->text);
}

sub xml {
   my $self = shift;

   if (! defined($self->input)) {
      return $self->log->info($self->help_set('input'));
   }

   my $xs = XML::Simple->new;

   return $xs->XMLin($self->text);
}

sub csv {
   my $self = shift;

   if (! defined($self->input)) {
      return $self->log->info($self->help_set('input'));
   }

   if (! defined($self->csv_separator)) {
      return $self->log->info($self->help_set('csv_separator'));
   }

   if (! defined($self->csv_format)) {
      return $self->log->info($self->help_set('csv_format'));
   }

   my $format = $self->csv_format;
   if ($format !~ /^aoh$/) {
      return $self->log->info($self->help_set('csv_format'));
   }

   my $data = Text::CSV::Hashify->new({
      file => $self->input,
      format => $format,
      sep_char => $self->csv_separator,
   }) or return $self->log->error("Text::CSV::Hashify: new");

   return $data->all;
}

sub csv_get_col_by_name {
   my $self = shift;
   my ($data, $type, $value) = @_;

   if (! $self->csv_has_header || @{$self->csv_header} == 0) {
      return $self->log->error("CSV has no header, can't do that");
   }

   if (! defined($data)) {
      return $self->log->info($self->help_run('csv'));
   }

   if (! defined($type)) {
      return $self->log->info($self->help_run('csv_get_col_by_name'));
   }

   if (! defined($value)) {
      return $self->log->info($self->help_run('csv_get_col_by_name'));
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

sub csv_get_col_by_number {
   my $self = shift;
   my ($data, $number) = @_;

   return $self->log->info("XXX: TODO");
}

1;

__END__

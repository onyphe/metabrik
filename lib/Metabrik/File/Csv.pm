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
         has_header => [ qw(0|1) ],
         format => [ qw(aoh|hoh) ],
         separator => [ qw(character) ],
         header => [ qw($column_header_list) ],
         key => [ qw(key) ],
         encoding => [ qw(utf8|ascii) ],
      },
      commands => {
         read => [ ],
         get_col_by_name => [ qw($data|$READ column_name column_value) ],
         get_col_by_number => [ qw($data|$READ integer) ],
      },
      require_modules => {
         'Text::CSV::Hashify' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => $self->global->input || '/tmp/input.txt',
         has_header => 0,
         header => [ ],
         format => 'aoh',
         separator => ';',
         encoding => 'utf8',
      },
   };
}

sub read {
   my $self = shift;

   if (! defined($self->input)) {
      return $self->log->error($self->brik_help_set('input'));
   }

   if (! defined($self->separator)) {
      return $self->log->error($self->brik_help_set('separator'));
   }

   if (! defined($self->format)) {
      return $self->log->error($self->brik_help_set('format'));
   }

   my $format = $self->format;
   if ($format !~ /^aoh$/ && $format !~ /^hoh$/) {
      return $self->log->error($self->brik_help_set('format'));
   }

   my $key = $self->key;

   my $data = Text::CSV::Hashify->new({
      file => $self->input,
      format => $format,
      sep_char => $self->separator,
      key => $key,
   }) or return $self->log->error("Text::CSV::Hashify: new");

   return $data->all;
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

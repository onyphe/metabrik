#
# $Id$
#
# file::read Brik
#
package Metabrik::Brik::File::Read;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub properties {
   my $self = shift;

   return {
      revision => '$Revision$',
      tags => [ qw(main file) ],
      attributes => {
         input => [ qw(SCALAR) ],
      },
      attributes_default => {
         input => $self->global->input || '/tmp/input.txt',
      },
      require_modules => {
         'File::Slurp' => [ ],
         'JSON::XS' => [ ],
         'XML::Simple' => [ ],
      },
   };
}

sub help {
   return {
      'set:input' => '<file>',
      'run:text' => '',
      'run:json' => '',
      'run:xml' => '',
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

1;

__END__

#
# $Id$
#
# Slurp brick
#
package Metabricky::Brick::File::Slurp;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   file
   separator
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub require_modules {
   return [
      'File::Slurp',
      'JSON::XS',
      'XML::Simple',
      'Text::CSV::Hashify',
   ];
}

sub help {
   return [
      'set file::slurp file <file>',
      'set file::slurp separator <separator>',
      'run file::slurp text',
      'run file::slurp json',
      'run file::slurp xml',
      'run file::slurp csv',
   ];
}

sub default_values {
   return {
      separator => ';',
   };
}

sub text {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   my $text = File::Slurp::read_file($self->file)
      or return $self->log->verbose("nothing to read from file [".$self->file."]");

   return $text;
}

sub json {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   return JSON::XS::decode_json($self->text);
}

sub xml {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   my $xs = XML::Simple->new;

   return $xs->XMLin($self->text);
}

sub csv {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   if (! defined($self->separator)) {
      return $self->log->info("set file::slurp separator <separator>");
   }

   my $obj = Text::CSV::Hashify->new({
      file => $self->file,
      format => 'aoh',
      sep_char => $self->separator,
   }) or return $self->log->error("Text::CSV::Hashify: new");

   return $obj->all;
}

1;

__END__

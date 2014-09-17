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
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub require_modules {
   return [
      'File::Slurp',
      'JSON::XS',
      'XML::Simple',
   ];
}

sub help {
   return [
      'set slurp file <file>',
      'run file::slurp text',
      'run file::slurp json',
      'run file::slurp xml',
   ];
}

sub text {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   my $text = read_file($self->file)
      or return $self->log->verbose("nothing to read from file [".$self->file."]");

   return $text;
}

sub json {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   return decode_json($self->text);
}

sub xml {
   my $self = shift;

   if (! defined($self->file)) {
      return $self->log->info("set file::slurp file <file>");
   }

   my $xs = XML::Simple->new;

   return $xs->XMLin($self->text);
}

1;

__END__

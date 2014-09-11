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
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use File::Slurp;
use JSON::XS;
use XML::Simple;

sub help {
   print "set slurp file <file>\n";
   print "\n";
   print "run file::slurp text\n";
   print "run file::slurp json\n";
   print "run file::slurp xml\n";
}

sub text {
   my $self = shift;

   if (! defined($self->file)) {
      die("set file::slurp file <file>\n");
   }

   my $text = read_file($self->file)
      or die("nothing to read from file [".$self->file."]\n");

   return $text;
}

sub json {
   my $self = shift;

   if (! defined($self->file)) {
      die("set file::slurp file <file>\n");
   }

   return decode_json($self->text);
}

sub xml {
   my $self = shift;

   if (! defined($self->file)) {
      die("set file::slurp file <file>\n");
   }

   my $xs = XML::Simple->new;

   return $xs->XMLin($self->text);
}

1;

__END__
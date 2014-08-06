#
# $Id$
#
# Slurp plugin
#
package Plashy::Plugin::Slurp;
use strict;
use warnings;

use base qw(Plashy::Plugin);

#our @AS = qw(
#);

__PACKAGE__->cgBuildIndices;
#__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use File::Slurp;
use JSON::XS;
use XML::Simple;

sub help {
   print "run slurp text\n";
   print "run slurp json\n";
   print "run slurp xml\n";
}

sub text {
   my $self = shift;

   if (! defined($self->global->file)) {
      die("you must set global file variable");
   }

   return read_file($self->global->file);
}

sub json {
   my $self = shift;

   return decode_json($self->text);
}

sub xml {
   my $self = shift;

   my $xs = XML::Simple->new;

   return $xs->XMLin($self->text);
}

1;

__END__

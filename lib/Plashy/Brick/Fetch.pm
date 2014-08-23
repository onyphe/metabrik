#
# $Id$
#
# Fetch brick
#
package Plashy::Brick::Fetch;
use strict;
use warnings;

use base qw(Plashy::Brick);

our @AS = qw(
   output
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub help {
   print "set fetch output <file>\n";
   print "\n";
   print "run fetch get <uri>\n";
}

sub get {
   my $self = shift;
   my ($uri) = @_;

   my $output = $self->output;
   if (! defined($output)) {
      die("set fetch output <file>\n");
   }

   if (! defined($uri)) {
      die("run fetch get <uri>\n");
   }

   # XXX: dirty for now
   for my $path (split(':', $ENV{PATH})) {
      if (-f "$path/wget") {
         my $ret = `$path/wget --output-document=$output $uri`;
         return !$ret;
      }
   }

   return die("wget binary not found\n");
}

1;

__END__

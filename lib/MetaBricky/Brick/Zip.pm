#
# $Id$
#
# Zip brick
#
package MetaBricky::Brick::Zip;
use strict;
use warnings;

use base qw(MetaBricky::Brick);

our @AS = qw(
   input
   output
   destdir
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub help {
   print "set zip input <file>\n";
   print "set zip output <file>\n";
   print "set zip destdir <destdir>\n";
   print "\n";
   print "run zip uncompress\n";
   print "run zip compress\n";
}

sub default_values {
   my $self = shift;

   return {
      destdir => $self->global->datadir,
   };
}

sub uncompress {
   my $self = shift;
   my ($destdir) = @_;

   my $input = $self->input;
   if (! defined($input)) {
      die("set zip input <file>\n");
   }

   my $dir = $self->destdir;
   if (! defined($dir)) {
      die("set zip destdir <destdir>\n");
   }

   # XXX: dirty for now
   for my $path (split(':', $ENV{PATH})) {
      if (-f "$path/unzip") {
         my $ret = `$path/unzip -o $input -d $dir/`;
         print "$ret\n";
         return !$?;
      }
   }

   return die("unzip binary not found\n");
}

1;

__END__

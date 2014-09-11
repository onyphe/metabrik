#
# $Id$
#
# Keystore brick
#
package Metabricky::Brick::Database::Keystore;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   file
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Metabricky::Brick::Crypto::Aes;
use Metabricky::Brick::File::Slurp;

sub help {
   print "set database::keystore file <file>\n";
   print "\n";
   print "run database::keystore search <pattern>\n";
   #print "run database::keystore add <data>\n";
   #print "run database::keystore remove <data>\n";
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($self->file)) {
      die("set database::keystore file <file>\n");
   }

   if (! defined($pattern)) {
      die("run database::keystore search <pattern>\n");
   }

   my $slurp = Metabricky::Brick::File::Slurp->new(
      global => $self->global,
      file => $self->file,
   );

   my $data = $slurp->text or die("can't slurp");

   my $aes = Metabricky::Brick::Crypto::Aes->new(
      global => $self->global,
   );

   my $decrypted = $aes->decrypt($data) or die("can't decrypt");

   my @lines = split(/\n/, $decrypted);
   for (@lines) {
      print "$_\n" if /$pattern/i;
   }

   return 1;
}

1;

__END__

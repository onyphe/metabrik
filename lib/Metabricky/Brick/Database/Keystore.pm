#
# $Id: Keystore.pm 89 2014-09-17 20:29:29Z gomor $
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
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'Metabricky::Brick::Crypto::Aes',
      'Metabricky::Brick::File::Slurp',
   ];
}

sub help {
   return [
      'set database::keystore file <file>',
      'run database::keystore search <pattern>',
   ];
      #'run database::keystore add <data>',
      #'run database::keystore remove <data>',
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($self->file)) {
      return $self->log->info("set database::keystore file <file>");
   }

   if (! defined($pattern)) {
      return $self->log->info("run database::keystore search <pattern>");
   }

   my $slurp = Metabricky::Brick::File::Slurp->new(
      file => $self->file,
      bricks => $self->bricks,
   );

   my $data = $slurp->text or return $self->log->error("can't slurp");

   my $aes = Metabricky::Brick::Crypto::Aes->new(
      bricks => $self->bricks,
   );

   my $decrypted = $aes->decrypt($data) or return $self->log->error("can't decrypt");

   my @lines = split(/\n/, $decrypted);
   for (@lines) {
      print "$_\n" if /$pattern/i;
   }

   return 1;
}

1;

__END__

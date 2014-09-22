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
      'Metabricky::Brick::File::Read',
   ];
}

sub help {
   return {
      'set:file' => '<file>',
      'run:search' => '<pattern>',
   };
      #'run:add' => '<data>',
      #'run:remove' => '<data>',
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (! defined($self->file)) {
      return $self->log->info($self->help_set('file'));
   }

   if (! defined($pattern)) {
      return $self->log->info($self->help_run('search'));
   }

   my $read = Metabricky::Brick::File::Read->new(
      input => $self->file,
      bricks => $self->bricks,
   );

   my $data = $read->text
      or return $self->log->error("can't read");

   my $aes = Metabricky::Brick::Crypto::Aes->new(
      bricks => $self->bricks,
   );

   my $decrypted = $aes->decrypt($data)
      or return $self->log->error("can't decrypt");

   my @lines = split(/\n/, $decrypted);
   for (@lines) {
      print "$_\n" if /$pattern/i;
   }

   return 1;
}

1;

__END__

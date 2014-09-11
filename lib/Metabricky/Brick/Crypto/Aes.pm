#
# $Id$
#
# AES brick
#
package Metabricky::Brick::Crypto::Aes;
use strict;
use warnings;

use base qw(Metabricky::Brick);

#our @AS = qw(
#);
__PACKAGE__->cgBuildIndices;
#__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Crypt::CBC;
use Crypt::OpenSSL::AES;

sub help {
   print "run crypto::aes encrypt <data>\n";
   print "run crypto::aes decrypt <data>\n";
}

sub encrypt {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      die("run crypto::aes encrypt <data>\n");
   }

   #my $key = 'key';

   #my $cipher = Crypt::CBC->new(
      #-key => $key,
      #-cipher => 'Crypt::OpenSSL::AES',
   #) or die("cipher: $!");

   #my $crypted = $cipher->encrypt_hex($data);

   # Will only return hex encoded data
   my $crypted = `echo "$data" | openssl enc -e -a -aes-128-cbc`;

   return $crypted;
}

sub decrypt {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      die("run crypto::aes decrypt <data>\n");
   }

   #my $key = 'key';

   #my $cipher = Crypt::CBC->new(
      #-key => $key,
      #-cipher => 'Crypt::OpenSSL::AES',
   #) or die("cipher: $!");

   #my $decrypted = $cipher->decrypt_hex($data);

   # Will only return hex decoded data
   my $decrypted = `echo "$data" | openssl enc -d -a -aes-128-cbc`;

   return $decrypted;
}

1;

__END__

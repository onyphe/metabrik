#
# $Id$
#
# Base64 brick
#
package MetaBricky::Brick::Base64;
use strict;
use warnings;

use base qw(MetaBricky::Brick);

#our @AS = qw(
#);
__PACKAGE__->cgBuildIndices;
#__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use MIME::Base64 qw(encode_base64 decode_base64);

sub help {
   print "run base64 encode <data>\n";
   print "run base64 decode <data>\n";
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      die("run base64 encode <data>\n");
   }

   my $encoded = encode_base64($data);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      die("run base64 decode <data>\n");
   }

   my $decoded = decode_base64($data);

   return $decoded;
}

1;

__END__

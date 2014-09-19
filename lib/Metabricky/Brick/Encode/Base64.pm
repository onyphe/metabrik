#
# $Id: Base64.pm 89 2014-09-17 20:29:29Z gomor $
#
# Base64 brick
#
package Metabricky::Brick::Encode::Base64;
use strict;
use warnings;

use base qw(Metabricky::Brick);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'MIME::Base64',
   ];
}

sub help {
   return [
      'run encode::base64 encode <data>',
      'run encode::base64 decode <data>',
   ];
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->info("run encode::base64 encode <data>");
   }

   my $encoded = MIME::Base64::encode_base64($data);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->info("run encode::base64 decode <data>");
   }

   my $decoded = MIME::Base64::decode_base64($data);

   return $decoded;
}

1;

__END__

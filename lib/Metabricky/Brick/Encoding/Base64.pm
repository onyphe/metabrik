#
# $Id: Base64.pm 89 2014-09-17 20:29:29Z gomor $
#
# encoding::base64 Brick
#
package Metabricky::Brick::Encoding::Base64;
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
   return {
      'run:encode' => '<data>',
      'run:decode' => '<data>',
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->info($self->help_run('encode'));
   }

   my $encoded = MIME::Base64::encode_base64($data);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->info($self->help_run('decode'));
   }

   my $decoded = MIME::Base64::decode_base64($data);

   return $decoded;
}

1;

__END__

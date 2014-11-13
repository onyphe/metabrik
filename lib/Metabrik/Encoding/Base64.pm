#
# $Id$
#
# encoding::base64 Brik
#
package Metabrik::Encoding::Base64;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable encode decode base64) ],
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'MIME::Base64' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('encode'));
   }

   my $encoded = MIME::Base64::encode_base64($data);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   if (! defined($data)) {
      return $self->log->error($self->brik_help_run('decode'));
   }

   my $decoded = MIME::Base64::decode_base64($data);

   return $decoded;
}

1;

__END__

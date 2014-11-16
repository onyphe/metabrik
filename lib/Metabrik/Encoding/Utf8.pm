#
# $Id: Base64.pm 89 2014-09-17 20:29:29Z gomor $
#
# encoding::base64 Brik
#
package Metabrik::Encoding::Utf8;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(TODO unstable encode decode utf8) ],
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

=head1 NAME

Metabrik::Encoding::Utf8 - encoding::utf8 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

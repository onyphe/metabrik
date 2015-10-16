#
# $Id$
#
# client::rest Brik
#
package Metabrik::Client::Rest;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable http client rest api) ],
      require_modules => {
         'Metabrik::String::Uri' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub content {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("content: no request has been made yet");
   }

   my $sx = Metabrik::String::Xml->new_from_brik($self) or return;
   return $sx->decode($last->content);
}

1;

__END__

=head1 NAME

Metabrik::Client::Rest - client::rest Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

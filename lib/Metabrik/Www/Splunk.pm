#
# $Id: Template.pm 360 2014-11-16 14:52:06Z gomor $
#
# www::splunk Brik
#
package Metabrik::Www::Splunk;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision: 360 $',
      tags => [ qw(unstable rest api splunk) ],
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         ssl_verify => 0,
      },
      commands => {
         apps_local => [ ],
      },
      require_used => {
         'client::www' => [ ],
         'encoding::xml' => [ ],
      },
   };
}

sub apps_local {
   my $self = shift;

   my $uri = $self->uri.'/services/apps/local';

   my $response = $self->get($uri) or return;

   return $self->context->run('encoding::xml', 'decode', $response->{body});
}

1;

__END__

=head1 NAME

Metabrik::Www::Splunk - www::splunk Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

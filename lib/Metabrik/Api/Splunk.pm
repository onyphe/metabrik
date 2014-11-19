#
# $Id$
#
# api::splunk Brik
#
package Metabrik::Api::Splunk;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
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

sub brik_init {
   my $self = shift->SUPER::brik_init(
      @_,
   ) or return 1; # Init already done

   my $username = $self->username;
   my $password = $self->password;
   if (! defined($username) || ! defined($password)) {
      return $self->log->error("brik_init: you have to give username and password Attributes");
   }

   return $self;
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

Metabrik::Api::Splunk - api::splunk Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

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
      tags => [ qw(unstable browser http client www javascript screenshot) ],
      attributes => {
         uri => [ qw(uri) ],
         ssl_verify => [ qw(0|1) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         timeout => [ qw(timeout) ],
         _client => [ qw(object|INTERNAL) ],
         _last => [ qw(object|INTERNAL) ],
      },
      attributes_default => {
         ssl_verify => 1,  # Inherited
         timeout => 5,
      },
      commands => {
         create_client => [ ],  # Inherited
         verify_server => [ qw(uri|OPTIONAL) ],  # Inherited
         get => [ qw(uri|OPTIONAL) ],
         response_header => [ ],
         response_code => [ ],
         response_content => [ ],
      },
      require_modules => {
         'Metabrik::String::Uri' => [ ],
      },
   };
}

sub create_client {
   my $self = shift;

   my $mech = $self->create_user_agent or return;

   return $self->_client($mech);
}

sub get {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $client;
   if (! defined($self->_client)) {
      $client = $self->create_client or return;
      $self->_client($client);
   }

   my $resp = $client->get($uri);

   return $self->_last($resp);
}

sub response_content {
   my $self = shift;

   if (! defined($self->_last)) {
      return $self->log->error("response_content: no request has been made yet");
   }

   return $self->_last->content;
}

sub response_code {
   my $self = shift;

   if (! defined($self->_last)) {
      return $self->log->error("response_code: no request has been made yet");
   }

   return $self->_last->code;
}

sub response_header {
   my $self = shift;

   if (! defined($self->_last)) {
      return $self->log->error("response_code: no request has been made yet");
   }

   return $self->_last->header;
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

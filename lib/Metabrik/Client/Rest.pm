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
         _client => [ qw(object|INTERNAL) ],
      },
      attributes_default => {
         ssl_verify => 1,  # Inherited
      },
      commands => {
         create_client => [ ],  # Inherited
         verify_server => [ qw(uri|OPTIONAL) ],  # Inherited
         get => [ qw(uri|OPTIONAL) ],
      },
      require_modules => {
         'REST::Client' => [ ],
         'Metabrik::String::Uri' => [ ],
      },
   };
}

sub create_client {
   my $self = shift;

   my $mech = $self->create_user_agent or return;

   my $client = REST::Client->new;
   if (! defined($client)) {
      return $self->log->error("create_client: unable to create REST::Client object");
   }

   # We replace default UA with our own
   $client->setUseragent($mech);

   $self->_client($client);

   return $client;
}

sub get {
   my $self = shift;
   my ($uri) = @_;

   if (! defined($self->_client)) {
      return $self->log->error($self->brik_help_run('create_client'));
   }

   $uri ||= $self->uri;
   if (! defined($uri)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   return $self->_client->GET($uri);
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

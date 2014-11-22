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
      attributes => {
         output_mode => [ qw(json|xml) ],
      },
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         ssl_verify => 1,
         output_mode => 'json',
      },
      commands => {
         apps_local => [ ],
      },
      require_used => {
         'string::xml' => [ ],
         'string::json' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $username = $self->username;
   my $password = $self->password;
   if (! defined($username) || ! defined($password)) {
      return $self->log->error("brik_init: you have to give username and password Attributes");
   }

   return $self->SUPER::brik_init;
}

sub apps_local {
   my $self = shift;

   my $mode = $self->output_mode;

   my $uri = $self->uri.'/services/apps/local?output_mode='.$mode;

   my $response = $self->get($uri) or return;

   #return $self->context->run('string::xml', 'decode', $response->{body});
   return $self->context->run('string::json', 'decode', $response->{body});
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

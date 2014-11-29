#
# $Id$
#
# network::http Brik
#
package Metabrik::Network::Http;
use strict;
use warnings;

use base qw(Metabrik::Client::Tcp);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable http) ],
      attributes => {
         host_header => [ qw(host_header) ],
      },
      commands => {
         probe => [ qw(host port|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Parse' => [ ],
      },
   };
}

sub probe {
   my $self = shift;
   my ($host, $port) = @_;

   $host ||= $self->host;
   $port ||= 80;

   if (! defined($host)) {
      return $self->log->error($self->brik_help_run('probe'));
   }

   my $probe = "GET / HTTP/1.0\r\n\r\n";
   if ($self->host_header) {
      $probe = "GET / HTTP/1.1\r\nHost: ".$self->host_header."\r\n\r\n";
   }

   $self->host($host);
   $self->port($port);
   $self->connect or return $self->log->error("probe: connect failed");
   $self->write($probe) or return $self->log->error("probe: write failed");
   my $response = $self->read or return $self->log->error("probe: read failed");
   $self->disconnect;

   if (length($response)) {
      my $parse = Metabrik::String::Parse->new;
      return $parse->to_array($response);
   }

   return $response;
}

1;

__END__

=head1 NAME

Metabrik::Network::Http - network::http Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

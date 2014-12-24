#
# $Id$
#
# server::http Brik
#
package Metabrik::Server::Http;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable server http) ],
      attributes => {
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         root_directory => [ qw(root_directory) ],
         _http => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 8888,
      },
      commands => {
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL root_directory|OPTIONAL) ],
      },
      require_modules => {
         'HTTP::Server::Brick' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         root_directory => $self->global->datadir.'/http',
      },
   };
}

sub brik_init {
   my $self = shift;

   if (! -d $self->root_directory) {
      mkdir($self->root_directory)
         or return $self->log->error("brik_init: cannot create directory");
   }

   my $restore = $SIG{INT};

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("brik_init: INT caught");
      kill('HUP', $$);
      $SIG{INT} = $restore;
      return 1;
   };

   return $self->SUPER::brik_init;
}

sub start {
   my $self = shift;
   my ($hostname, $port, $root) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $root ||= $self->root_directory;

   my $http = HTTP::Server::Brick->new(
      port => $port,
      host => $hostname,
      timeout => $self->global->rtimeout,
   );

   $http->mount('/' => { path => $root });

   return $self->_http($http)->start;
}

1;

__END__

=head1 NAME

Metabrik::Server::Http - server::http Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

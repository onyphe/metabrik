#
# $Id$
#
# server::elasticsearch Brik
#
package Metabrik::Server::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::System::Service Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable elk) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         listen => [ qw(ip_address) ],
         port => [ qw(port) ],
         conf_file => [ qw(file) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 9200,
      },
      commands => {
         install => [ ], # Inherited
         start => [ ], # Inherited
         stop => [ ], # Inherited
         status => [ ], # Inherited
         restart => [ ], # Inherited
         generate_conf => [ qw(conf|OPTIONAL) ],
         # XXX: ./bin/plugin -install lmenezes/elasticsearch-kopf
         #install_plugin => [ qw(plugin) ],
      },
      need_packages => {
         ubuntu => [ qw(elasticsearch) ],
      },
      need_services => {
         ubuntu => [ qw(elasticsearch) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;

   return {
      attributes_default => {
         conf_file => "$datadir/elasticsearch.xml",
      },
   };
}

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $self->log->info("TO DO");

   $conf_file ||= $self->conf_file;

   return $conf_file;
}

1;

__END__

=head1 NAME

Metabrik::Server::Elasticsearch - server::elasticsearch Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id$
#
# server::elasticsearch Brik
#
package Metabrik::Server::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::System::Package Metabrik::System::Process);

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
         pidfile => [ qw(file) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 9200,
      },
      commands => {
         install => [ ], # Inherited
         start => [ ],
         stop => [ ],
         generate_conf => [ qw(conf|OPTIONAL) ],
         # XXX: ./bin/plugin -install lmenezes/elasticsearch-kopf
         #install_plugin => [ qw(plugin) ],
      },
      require_modules => {
         'Metabrik::System::Process' => [ ],
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

sub start {
   my $self = shift;

   $self->close_output_on_start(1);

   my $pidfile = $self->SUPER::start(sub {
      my $pid = $self->write_pidfile;
      $self->log->info("Within daemon with pid[$pid]");

      my $cmd = '/usr/share/elasticsearch/bin/elasticsearch';

      $self->sudo_system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

   $self->log->verbose("here");

   $self->wait_for_pidfile($pidfile) or return;

   $self->pidfile($pidfile);

   return $pidfile;
}

sub stop {
   my $self = shift;

   my $pidfile = $self->pidfile;
   if (! defined($pidfile)) {
      $self->log->warning("stop: nothing to stop");
      return 1;
   }

   return $self->kill_from_pidfile($pidfile);
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

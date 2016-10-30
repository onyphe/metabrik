#
# $Id$
#
# server::elasticsearch Brik
#
package Metabrik::Server::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::System::Process);

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
         version => [ qw(2.4.1|5.0.0) ],
         no_output => [ qw(0|1) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 9200,
         version => '5.0.0',
         no_output => 1,
      },
      commands => {
         install => [ ],
         start => [ ],
         stop => [ ],
         generate_conf => [ qw(conf|OPTIONAL) ],
         # XXX: ./bin/plugin -install lmenezes/elasticsearch-kopf
         #install_plugin => [ qw(plugin) ],
         status => [ ],
      },
      require_binaries => {
         tar => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tar openjdk-8-jre-headless) ],
         debian => [ qw(tar openjdk-8-jre-headless) ],
         freebsd => [ qw(openjdk elasticsearch2) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $pidfile = $datadir.'/daemon.pid';

   my $conf_file = $datadir.'/elasticsearch-'.$version.'/config/elasticsearch.xml';

   return {
      attributes_default => {
         conf_file => $conf_file,
         pidfile => $pidfile,
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

sub install {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $she = $self->shell;

   my $url = 'https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.0.0.tar.gz';
   if ($version eq '2.4.1') {
      $url = 'https://download.elastic.co/elasticsearch/release/org/'.
             'elasticsearch/distribution/tar/elasticsearch/2.4.1/'.
             'elasticsearch-2.4.1.tar.gz';
   }

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->mirror($url, "$datadir/es.tar.gz") or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "tar zxvf es.tar.gz";
   my $r = $self->execute($cmd) or return;

   $she->run_cd($cwd) or return;

   return 1;
}

sub start {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $no_output = $self->no_output;

   # If already started, we return.
   if ($self->status) {
      return 1;
   }

   $self->close_output_on_start($no_output);

   my $pidfile = $datadir.'/daemon.pid';

   $self->use_pidfile(0);

   $self->SUPER::start(sub {
      $self->log->verbose("Within daemon");

      my $cmd = $datadir.'/elasticsearch-'.$version.'/bin/elasticsearch -p '.
         $datadir.'/daemon.pid';

      $self->system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

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

sub status {
   my $self = shift;

   my $pidfile = $self->pidfile;

   if (-f $pidfile) {
      $self->log->verbose("status: process is running");
      return 1;
   }

   $self->log->verbose("status: process NOT running");
   return 0;
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

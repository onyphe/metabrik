#
# $Id$
#
# server::kibana Brik
#
package Metabrik::Server::Kibana;
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
         version => [ qw(4.6.2|5.0.0) ],
         no_output => [ qw(0|1) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 5601,
         version => '5.0.0',
         no_output => 0,
      },
      commands => {
         install => [ ],
         start => [ ],
         stop => [ ],
         generate_conf => [ qw(conf|OPTIONAL) ],
         status => [ ],
      },
      require_modules => {
         'Metabrik::System::Process' => [ ],
      },
      require_binaries => {
         tar => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tar openjdk-8-jre-headless) ],
         debian => [ qw(tar openjdk-8-jre-headless) ],
         freebsd => [ qw(openjdk node012 kibana45) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;

   #my $conf_file = $datadir.'/elasticsearch-'.$version.'/config/elasticsearch.xml';

   return {
      #attributes_default => {
         #conf_file => $conf_file,
      #},
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

   my $url = 'https://artifacts.elastic.co/downloads/kibana/kibana-5.0.0-linux-x86_64.tar.gz';
   if ($version eq '4.6.2') {
      $url = 'https://download.elastic.co/kibana/kibana/kibana-4.6.2-linux-x86_64.tar.gz';
   }

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->mirror($url, "$datadir/kibana.tar.gz") or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "tar zxvf kibana.tar.gz";
   my $r = $self->execute($cmd) or return;

   $she->run_cd($cwd) or return;

   return 1;
}

#
# /usr/local/bin/node /usr/local/www/kibana44/src/cli serve --config /usr/local/etc/kibana.yml --log-file /var/log/kibana.log
#
sub start {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $no_output = $self->no_output;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   if ($sp->is_running('node')) {
      return $self->log->error("start: process already running");
   }

   $self->close_output_on_start($no_output);

   my $binary = $datadir.'/kibana-'.$version.'-linux-x86_64/bin/kibana';
   $self->brik_help_run_file_not_found('start', $binary) or return;

   $self->SUPER::start(sub {
      $self->log->verbose("Within daemon");

      # -p port, -l log-file -c config-file -e elasticsearch-uri
      my $cmd = $datadir.'/kibana-'.$version.'-linux-x86_64/bin/kibana -Q';

      $self->system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

   return 1;
}

sub stop {
   my $self = shift;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   if (! $sp->is_running('node')) {
      return $self->log->info("stop: process NOT running");
   }

   return $self->kill('node');
}

sub status {
   my $self = shift;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   if ($sp->is_running('node')) {
      $self->log->verbose("status: process 'node' is running");
      return 1;
   }

   $self->log->verbose("status: process 'node' is NOT running");
   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Server::Kibana - server::kibana Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

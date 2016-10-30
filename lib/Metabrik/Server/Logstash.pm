#
# $Id$
#
# server::logstash Brik
#
package Metabrik::Server::Logstash;
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
         conf_file => [ qw(file) ],
         pidfile => [ qw(file) ],
         version => [ qw(5.0.0) ],
         no_output => [ qw(0|1) ],
      },
      attributes_default => {
         version => '5.0.0',
         no_output => 0,
      },
      commands => {
         install => [ ],
         check_config => [ qw(conf) ],
         start => [ qw(conf) ],
         start_in_foreground => [ qw(conf) ],
         stop => [ ],
         generate_conf => [ qw(conf|OPTIONAL) ],
         status => [ ],
      },
      require_binaries => {
         tar => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tar openjdk-8-jre-headless) ],
         debian => [ qw(tar openjdk-8-jre-headless) ],
         freebsd => [ qw(openjdk logstash) ],
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
   my $she = $self->shell;

   my $url = 'https://artifacts.elastic.co/downloads/logstash/logstash-5.0.0.tar.gz';

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->mirror($url, "$datadir/logstash.tar.gz") or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "tar zxvf logstash.tar.gz";
   my $r = $self->execute($cmd) or return;

   $she->run_cd($cwd) or return;

   return 1;
}

sub check_config {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('start', $file) or return;

   my $datadir = $self->datadir;
   my $version = $self->version;

   my $cmd = $datadir.'/logstash-'.$version.'/bin/logstash -t -f '.$file;

   $self->log->info("check_config: running...");

   return $self->system($cmd);
}

#
# logstash -f <config_file> -l <log_file>
#
sub start {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('start', $file) or return;
   $self->brik_help_run_file_not_found('start', $file) or return;

   # Make if a full path file
   if ($file !~ m{^/}) {
      my $cwd = $self->shell->full_pwd;
      $file = $cwd.'/'.$file;
   }

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $no_output = $self->no_output;

   my $binary = $datadir.'/logstash-'.$version.'/bin/logstash';
   $self->brik_help_run_file_not_found('start', $binary) or return;

   $self->log->verbose("start: using binary[$binary]");

   $self->close_output_on_start($no_output);

   $self->SUPER::start(sub {
      $self->log->verbose("Within daemon");

      my $cmd = $binary.' -f '.$file;

      $self->system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

   return 1;
}

sub start_in_foreground {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('start_in_foreground', $file) or return;

   my $datadir = $self->datadir;
   my $version = $self->version;

   my $cmd = $datadir.'/logstash-'.$version.'/bin/logstash -f '.$file;

   return $self->system($cmd);
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

   return $self->log->info("TODO");
}

1;

__END__

=head1 NAME

Metabrik::Server::Logstash - server::logstash Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

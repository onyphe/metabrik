#
# $Id$
#
# server::redis Brik
#
package Metabrik::Server::Redis;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         version => [ qw(version) ],
         conf => [ qw(file) ],
         listen => [ qw(address) ],
         port => [ qw(port) ],
      },
      attributes_default => {
         conf => 'redis.conf',
         listen => '127.0.0.1',
         port => 6379,
      },
      commands => {
         install => [ ],  # Inherited
         generate_conf => [ qw(conf|OPTIONAL port|OPTIONAL listen|OPTIONAL) ],
         start => [ qw(port|OPTIONAL listen|OPTIONAL) ],
         stop => [ ],
         status => [ ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Process' => [ ],
      },
      require_binaries => {
         'redis-server' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(redis-server) ],
         debian => [ qw(redis-server) ],
      },
   };
}

sub generate_conf {
   my $self = shift;
   my ($conf, $port, $listen) = @_;

   my $datadir = $self->datadir;
   $conf ||= $datadir.'/'.$self->conf;

   $port ||= $self->port;
   $listen ||= $self->listen;

   my $lib_dir = 'var/lib/redis';
   my $log_dir = 'var/log/redis';
   my $run_dir = 'var/run/redis';

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($datadir.'/'.$lib_dir) or return;
   $sf->mkdir($datadir.'/'.$log_dir) or return;
   $sf->mkdir($datadir.'/'.$run_dir) or return;

   my $dir = $self->datadir.'/'.$lib_dir;
   my $logfile = $self->datadir.'/'.$log_dir.'/redis-server.log';
   my $pidfile = $self->datadir.'/'.$run_dir.'/redis-server.pid';

   my $params = {
      "daemonize" => "yes",
      "bind" => $listen,
      "dir" => $dir,
      "logfile" => $logfile,
      "pidfile" => $pidfile,
      "port" => $port,
      "client-output-buffer-limit" => [
         'normal 0 0 0',
         'slave 256mb 64mb 60',
         'pubsub 32mb 8mb 60',
      ],
      "databases" => 16,
      "activerehashing" => "yes",
      "aof-load-truncated" => "yes",
      "aof-rewrite-incremental-fsync" => "yes",
      "appendfilename" => "\"appendonly.aof\"",
      "appendfsync" => "everysec",
      "appendonly" => "no",
      "auto-aof-rewrite-min-size" => "64mb",
      "auto-aof-rewrite-percentage" => 100,
      "dbfilename" => "dump.rdb",
      "hash-max-ziplist-entries" => 512,
      "hash-max-ziplist-value" => 64,
      "hll-sparse-max-bytes" => 3000,
      "hz" => 10,
      "latency-monitor-threshold" => 0,
      "list-max-ziplist-entries" => 512,
      "list-max-ziplist-value" => 64,
      "loglevel" => "notice",
      "lua-time-limit" => 5000,
      "no-appendfsync-on-rewrite" => "no",
      "notify-keyspace-events" => "\"\"",
      "rdbchecksum" => "yes",
      "rdbcompression" => "yes",
      "repl-disable-tcp-nodelay" => "no",
      "repl-diskless-sync" => "no",
      "repl-diskless-sync-delay" => 5,
      "save" => 60,
      "set-max-intset-entries" => 512,
      "slave-priority" => 100,
      "slave-read-only" => "yes",
      "slave-serve-stale-data" => "yes",
      "slowlog-log-slower-than" => 10000,
      "slowlog-max-len" => 128,
      "stop-writes-on-bgsave-error" => "yes",
      "tcp-backlog" => 511,
      "tcp-keepalive" => 0,
      "timeout" => 0,
      "zset-max-ziplist-entries" => 128,
      "zset-max-ziplist-value" => 64,
   };

   my @lines = ();
   for my $k (keys %$params) {
      if (ref($params->{$k}) eq 'ARRAY') {
         for my $this (@{$params->{$k}}) {
            push @lines, "$k $this";
         }
      }
      else {
         push @lines, "$k ".$params->{$k};
      }
   }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);
   $ft->write(\@lines, $conf) or return;

   return $conf;
}

#
# redis-server --port 9999 --slaveof 127.0.0.1 6379
# redis-server /etc/redis/6379.conf --loglevel debug
#
sub start {
   my $self = shift;
   my ($port, $listen) = @_;

   $port ||= $self->port;
   $listen ||= $self->listen;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   if ($sp->is_running('redis-server')) {
      return $self->log->info("start: process already started");
   }

   my $datadir = $self->datadir;
   my $conf = $datadir.'/'.$self->conf;

   my $cmd = "redis-server $conf";
   if ($port) {
      $cmd .= " --port $port";
   }
   if ($listen) {
      $cmd .= " --bind $listen";
   }

   return $self->system($cmd);
}

sub stop {
   my $self = shift;

   my $datadir = $self->datadir;
   my $run_dir = 'var/run/redis';
   my $pidfile = $self->datadir.'/'.$run_dir.'/redis-server.pid';

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   if ($sp->is_running_from_pidfile($pidfile)) {
      $sp->kill_from_pidfile($pidfile) or return;
   }

   return $pidfile;
}

sub status {
   my $self = shift;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   if ($sp->is_running('redis-server')) {
      $self->log->verbose("status: process 'redis-server' is running");
      return 1;
   }

   $self->log->verbose("status: process 'redis-server' is NOT running");
   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Server::Redis - server::redis Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

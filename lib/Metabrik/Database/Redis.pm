#
# $Id$
#
# database::redis Brik
#
package Metabrik::Database::Redis;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         server => [ qw(ip_address) ],
         port => [ qw(port) ],
         _redis => [ ],
      },
      attributes_default => {
         server => '127.0.0.1',
         port => 6379,
      },
      commands => {
         install => [ ],
         start => [ ],
         stop => [ ],
         status => [ ],
         connect => [ ],
         command => [ qw(command $arg1 $arg2 ... $argN) ],
         time => [ ],
         disconnect => [ ],
         quit => [ ],  # Same as disconnect
         dbsize => [ ],
         exists => [ qw(key) ],
         get => [ qw(key) ],
         set => [ qw(key value) ],
         del => [ qw(key) ],
         mget => [ qw($key_list) ],
         hset => [ qw(key $hash) ],
         hget => [ qw(key hash_field) ],
         hgetall => [ qw(key) ],
      },
      require_modules => {
         'Redis' => [ ],
         'Metabrik::System::Package' => [ ],
         'Metabrik::System::Service' => [ ],
      },
   };
}

sub install {
   my $self = shift;

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   if ($sp->is_os_ubuntu) {
      $sp->install('redis-server') or return;
   }
   else {
      return $self->log->error("install: don't know how to do with this OS");
   }

   return 1;
}

sub start {
   my $self = shift;

   my $r;
   my $ss = Metabrik::System::Service->new_from_brik_init($self) or return;
   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   if ($sp->is_os_ubuntu) {
      $r = $ss->start('redis-server') or return;
   }
   else {
      return $self->log->error("start: don't know how to do with this OS");
   }

   return $r;
}

sub stop {
   my $self = shift;

   my $r;
   my $ss = Metabrik::System::Service->new_from_brik_init($self) or return;
   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   if ($sp->is_os_ubuntu) {
      $r = $ss->stop('redis-server') or return;
   }
   else {
      return $self->log->error("stop: don't know how to do with this OS");
   }

   return $r;
}

sub status {
   my $self = shift;

   my $r;
   my $ss = Metabrik::System::Service->new_from_brik_init($self) or return;
   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   if ($sp->is_os_ubuntu) {
      $r = $ss->status('redis-server') or return;
   }
   else {
      return $self->log->error("stop: don't know how to do with this OS");
   }

   return $r;
}

sub connect {
   my $self = shift;

   my $redis = Redis->new(
      server => $self->server.':'.$self->port,
      name => 'redis_connection',
      cnx_timeout => $self->global->ctimeout,
      read_timeout => $self->global->rtimeout,
      write_timeout => $self->global->rtimeout,
   ) or return $self->log->error("connect: redis connection error");

   return $self->_redis($redis);
}

sub _get_redis {
   my $self = shift;

   my $redis = $self->_redis;
   if (! defined($redis)) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   return $redis;
}

# Command list: http://redis.io/commands

sub command {
   my $self = shift;
   my ($cmd, @args) = @_;

   my $redis = $self->_get_redis or return;

   my $r = $redis->$cmd(@args);
   if (! defined($r)) {
      return $self->log->error("command: $cmd failed");
   }

   return $r;
}

sub time {
   my $self = shift;

   return $self->command('time');
}

sub disconnect {
   my $self = shift;

   my $r = $self->command('quit') or return;
   $self->_redis(undef);

   return $r;
}

sub quit {
   my $self = shift;

   return $self->disconnect;
}

sub dbsize {
   my $self = shift;

   return $self->command('dbsize');
}

sub exists {
   my $self = shift;
   my ($key) = @_;

   $self->brik_help_run_undef_arg('exists', $key) or return;

   return $self->command('exists', $key);
}

sub get {
   my $self = shift;
   my ($key) = @_;

   $self->brik_help_run_undef_arg('get', $key) or return;

   return $self->command('get', $key);
}

sub set {
   my $self = shift;
   my ($key, $value) = @_;

   $self->brik_help_run_undef_arg('set', $key) or return;
   $self->brik_help_run_undef_arg('set', $value) or return;

   return $self->command('set', $key, $value);
}

sub del {
   my $self = shift;
   my ($key) = @_;

   $self->brik_help_run_undef_arg('del', $key) or return;

   return $self->command('del', $key);
}

sub mget {
   my $self = shift;
   my ($key_list) = @_;

   $self->brik_help_run_undef_arg('mget', $key_list) or return;
   $self->brik_help_run_invalid_arg('mget', $key_list, 'ARRAY') or return;

   return $self->command('mget', @$key_list);
}

sub hset {
   my $self = shift;
   my ($hashname, $hash) = @_;

   $self->brik_help_run_undef_arg('hset', $hashname) or return;
   $self->brik_help_run_undef_arg('hset', $hash) or return;
   $self->brik_help_run_invalid_arg('hset', $hash, 'HASH') or return;

   my $redis = $self->_get_redis or return;

   for (keys %$hash) {
      $redis->hset($hashname, $_, $hash->{$_}) or next;
   }

   $redis->wait_all_responses;

   return $hash;
}

sub hget {
   my $self = shift;
   my ($hashname, $field) = @_;

   $self->brik_help_run_undef_arg('hget', $hashname) or return;
   $self->brik_help_run_undef_arg('hget', $field) or return;

   return $self->command('hget', $hashname, $field);
}

sub hgetall {
   my $self = shift;
   my ($hashname) = @_;

   $self->brik_help_run_undef_arg('hgetall', $hashname) or return;

   my $r = $self->command('hgetall', $hashname) or return;

   my %h = @{$r};

   return \%h;
}

1;

__END__

=head1 NAME

Metabrik::Database::Redis - database::redis Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
